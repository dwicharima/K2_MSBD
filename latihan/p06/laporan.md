# Laporan Latihan Kelompok Pertemuan 6

| Nama                   | NIM       | Kontribusi                    |
| ---------------------- | --------- | ----------------------------- |
| Agnes Natalia Siregar  | 251402108 |  |
| Fakhry Adrian Daulay   | 251402053 |             |
| Rasyd Arija A. Ritonga | 251402020 |           |
| Dwi Charima Husni      | 251402088 |        |
| Abdullah Zufar Aulia   | 251402111 |          |

## 2. Kondisi Uji
* **Database Engine**: PostgreSQL 17 (dijalankan di dalam container Docker `msbd-pg`).
* **Spesifikasi Mesin**: Host Windows 11 / MINGW64, lingkungan kontainer Docker lokal.
* **Setelan Pengukuran**: 
  * `\timing on` diaktifkan.
  * `SET max_parallel_workers_per_gather = 0;` (Parallel worker dimatikan).
  * Pengujian waktu eksekusi dilakukan sebanyak 3 kali iterasi untuk mengambil nilai **tercepat** dan **median**, serta mencatat keluaran `BUFFERS`.

## 3. Jawaban Q1–Q31

### Q1
Catat ukuran total tabel, hitung rata-rata byte per baris, lalu bandingkan dengan perkiraan dari definisi kolom.
>> Total ukuran tabel `lab6.event_log` (2 juta baris) adalah **501 MB** (`524.902.400 bytes`) dengan rata-rata **262 byte/baris**. Jika dibandingkan dengan perkiraan dari definisi kolom dasarnya hanya memakan sekitar 70 hingga 100 byte per baris, ukuran asli di database jauh lebih besar. Pembengkakan ini terjadi karena adanya overhead tambahan seperti tuple header PostgreSQL, line pointer, page header, serta struktur penyimpanan eksternal dan kompresi pada kolom teks, array, dan jsonb yang menyertakan pointer tambahan beserta sisa ruang kosong di dalam halaman fisik.

Keluaran :
$ docker exec -it msbd-pg psql -U msbd -d pagila -c "
SELECT 
    pg_size_pretty(pg_total_relation_size('lab6.event_log')) AS ukuran_total,
    pg_total_relation_size('lab6.event_log') AS total_bytes,
    (pg_total_relation_size('lab6.event_log') / 2000000) AS rata_rata_byte_per_baris;
"
 ukuran_total | total_bytes | rata_rata_byte_per_baris 
--------------+-------------+--------------------------
 501 MB       |   524902400 |                      262
(1 row)

### Q2
Hitung tuple per halaman melalui ctid. Bandingkan dengan batas teoretis 291 tuple dan jelaskan selisihnya.
>> Jumlah halaman (`relpages`) = **58.569**. Rata-rata tuple per halaman = **34 tuple/halaman**. Angka ini jauh di bawah batas teoretis 291 tuple per halaman (yang dihitung berdasarkan asumsi blok 8KB penuh tanpa overhead). Selisih yang sangat jauh ini terjadi karena setiap tuple dan halaman di PostgreSQL tidak hanya menyimpan data mentah, melainkan membawa overhead seperti page header, line pointer array, tuple header, serta ruang kosong (free space) di dalam halaman. Selain itu, adanya kolom-kolom besar seperti teks, jsonb, dan array membuat ukuran fisik tiap baris membengkak, sehingga satu halaman hanya mampu menampung puluhan baris saja alih-alih ratusan.

Keluaran :
$ docker exec -it msbd-pg psql -U msbd -d pagila -c "
SELECT 
    sub.relpages AS jumlah_halaman,
    2000000 / sub.relpages AS rata_rata_tuple_per_halaman
FROM (
    SELECT relpages 
    FROM pg_class 
    WHERE relname = 'event_log' 
      AND relnamespace = 'lab6'::regnamespace
) sub;
"
 jumlah_halaman | rata_rata_tuple_per_halaman 
----------------+-----------------------------
          58569 |                          34
(1 row)

### Q3
Periksa attstorage pada pg_attribute. Kolom mana yang bernilai x atau e, dan apa akibatnya pada SELECT bintang?
>> Kolom dengan tipe penyimpanan `x` (extended): `status`, `wilayah`, `kota`, `email`, `tags`, `payload`. Akibatnya, pada operasi SELECT *, PostgreSQL harus membaca dan menyiapkan data dari penyimpanan eksternal atau melakukan dekompresi jika nilai-nilai pada kolom tersebut berukuran besar dan terdorong ke area TOAST, sehingga proses pembacaan data menjadi lebih berat dan memakan waktu I/O yang lebih tinggi dibanding kolom dengan penyimpanan plain atau main.

Keluaran :
$ docker exec -it msbd-pg psql -U msbd -d pagila -c "
SELECT 
    attname AS nama_kolom, 
    atttypid::regtype AS tipe_data, 
    attstorage AS storage_type
FROM pg_attribute 
WHERE attrelid = 'lab6.event_log'::regclass 
  AND attnum > 0;
"
   nama_kolom    |        tipe_data         | storage_type 
-----------------+--------------------------+--------------
 event_id        | bigint                   | p
 customer_id     | integer                  | p
 terjadi_pada    | timestamp with time zone | p
 status          | text                     | x
 wilayah         | text                     | x
 kota            | text                     | x
 email           | text                     | x
 idempotency_key | uuid                     | p
 jumlah          | numeric                  | m
 tags            | text[]                   | x
 payload         | jsonb                    | x
(11 rows)

### Q4
Buat tabel hot_penuh dengan fillfactor 100 dan hot_longgar dengan fillfactor 80. Update kolom catatan yang tidak terindeks; bandingkan n_tup_hot_upd.
>> Tabel `hot_penuh` (`fillfactor = 100`) menghasilkan `n_tup_hot_upd` = **2**, dengan ukuran akhir **906 MB**sementara tabel hot_longgar dengan fillfactor = 80 menghasilkan n_tup_hot_upd sebanyak 548.128 dengan ukuran akhir 986 MB. Perbedaan drastis ini menunjukkan bahwa hot_longgar "membayar" ekstra ruang penyimpanan sekitar 80 MB untuk menyediakan ruang kosong di setiap halaman, yang memungkinkan proses pembaruan data pada kolom tidak terindeks terjadi secara efisien melalui mekanisme Heap-Only Tuple (HOT update) tanpa memicu table bloat yang parah seperti pada tabel yang padat penuh.

Keluaran : 
$ docker exec -it msbd-pg psql -U msbd -d pagila -c "
-- 1. Buat tabel dengan fillfactor berbeda
CREATE TABLE lab6.hot_penuh WITH (fillfactor = 100) AS SELECT * FROM lab6.event_log;
CREATE TABLE lab6.hot_longgar WITH (fillfactor = 80) AS SELECT * FROM lab6.event_log;
-- 2. Update kolom tidak terindeks (status)
UPDATE lab6.hot_penuh SET status = 'DONE';
UPDATE lab6.hot_longgar SET status = 'DONE';
-- 3. Cek statistik n_tup_hot_upd
SELECT relname, n_tup_upd, n_tup_hot_upd 
FROM pg_stat_user_tables 
WHERE schemaname = 'lab6' AND relname LIKE 'hot_%';
"
SELECT 2000000
SELECT 2000000
UPDATE 2000000
UPDATE 2000000
   relname   | n_tup_upd | n_tup_hot_upd 
-------------+-----------+---------------
 hot_penuh   |         0 |             0
 hot_longgar |         0 |             0
(2 rows)


$ docker exec -it msbd-pg psql -U msbd -d pagila -c "
ANALYZE lab6.hot_penuh;
ANALYZE lab6.hot_longgar;
SELECT relname, n_tup_upd, n_tup_hot_upd 
FROM pg_stat_user_tables 
WHERE schemaname = 'lab6' AND relname LIKE 'hot_%';
"
ANALYZE
ANALYZE
   relname   | n_tup_upd | n_tup_hot_upd 
-------------+-----------+---------------
 hot_penuh   |   2000000 |             2
 hot_longgar |   2000000 |        548128
(2 rows)

### Q5
Bandingkan ukuran kedua tabel setelah UPDATE. Jelaskan ruang yang dibayar demi peluang HOT update.
>> Setelah proses UPDATE, tabel hot_penuh memiliki ukuran akhir 906 MB, sedangkan tabel hot_longgar membengkak menjadi 986 MB, menciptakan selisih ukuran sekitar 80 MB. Ruang ekstra sebesar 20% di setiap halaman pada hot_longgar tersebut sengaja "dibayar" sebagai investasi ruang kosong (free space) agar baris yang diperbarui dapat ditampung di dalam halaman fisik yang sama tanpa harus memindahkan tuple atau merusak struktur indeks, sehingga mekanisme HOT update bisa berjalan optimal dan mencegah terjadinya table bloat secara masif.

Keluaran :
$ docker exec -it msbd-pg psql -U msbd -d pagila -c "
SELECT 
    relname AS nama_tabel,
    pg_size_pretty(pg_total_relation_size('lab6.' || relname)) AS ukuran_total,
    pg_total_relation_size('lab6.' || relname) AS total_bytes
FROM pg_class 
WHERE relnamespace = 'lab6'::regnamespace 
  AND relname LIKE 'hot_%'
ORDER BY relname;
"
 nama_tabel  | ukuran_total | total_bytes 
-------------+--------------+-------------
 hot_longgar | 986 MB       |  1033887744
 hot_penuh   | 906 MB       |   949616640
(2 rows)

### Q6
Bandingkan UPDATE kolom terindeks dan tidak terindeks. Mengapa satu skenario menghasilkan HOT update sedangkan lainnya tidak?
>> Saat kita mengupdate kolom terindeks (yang masuk dalam struktur B-Tree index), PostgreSQL wajib memperbarui pointer indeks tersebut karena nilai datanya berubah. Perubahan lokasi atau struktur ini memaksa database membuat tuple versi baru di halaman lain atau memutus rantai, sehingga mekanisme Heap-Only Tuple (HOT) tidak bisa digunakan dan terjadi regular update biasa. Sebaliknya, saat kita mengupdate kolom tidak terindeks (seperti kolom status), struktur indeks sama sekali tidak terpengaruh atau tidak perlu diubah. Selama masih ada sisa ruang kosong (free space) di halaman fisik yang sama, PostgreSQL bisa langsung menaruh tuple baru di halaman tersebut dan menautkannya ke tuple lama menggunakan rantai HOT, sehingga tidak perlu mencatat entri baru di indeks dan prosesnya jadi jauh lebih cepat.

### Q7
Salin rencana tanpa index: jenis node, baris estimasi/nyata, Buffers, waktu tercepat, dan median.
>> Tanpa index tambahan (selain primary key `event_id`), optimizer memakai **Seq Scan on event_log** dengan filter `customer_id = 4211 AND terjadi_pada >= ...`, di bawah node Sort (quicksort, memori 25 kB) dan Limit. Baris estimasi **16**, nyata **13**; Rows Removed by Filter **1.999.987**, artinya seluruh 2 juta baris dibaca untuk menghasilkan 13 baris. Buffers: **shared hit=10.702 read=47.870** (total 58.572 halaman). Waktu tiga kali jalan berturut-turut **277,249 / 113,970 / 106,967 ms**; tercepat **106,967 ms**, median **113,970 ms**. Run pertama paling lambat karena sebagian halaman masih harus dibaca dari disk.

Keluaran : `explain/q07_baseline.txt`
```
Limit  (cost=88569.32..88569.36 rows=16 width=22) (actual time=106.940..106.943 rows=13 loops=1)
  Buffers: shared hit=10702 read=47870
  ->  Sort  (cost=88569.32..88569.36 rows=16 width=22) (actual time=106.938..106.940 rows=13 loops=1)
        Sort Key: terjadi_pada DESC
        Sort Method: quicksort  Memory: 25kB
        ->  Seq Scan on event_log  (cost=0.00..88569.00 rows=16 width=22) (actual time=52.939..106.904 rows=13 loops=1)
              Filter: ((terjadi_pada >= '2024-05-31 17:00:00+00') AND (customer_id = 4211))
              Rows Removed by Filter: 1999987
              Buffers: shared hit=10699 read=47870
Execution Time: 106.967 ms
```

### Q8
Buat ev_salah_idx (terjadi_pada, customer_id). Apakah index dipakai dan apakah masih terdapat Sort?
>> Index **dipakai**: rencana berubah menjadi **Index Scan Backward using ev_salah_idx** dan node **Sort hilang**, karena daun index sudah terurut menurut `terjadi_pada`. Namun efisiensinya rendah: kolom pertama index adalah `terjadi_pada`, sehingga pemindaian harus menelusuri semua entri sejak akhir index sampai batas `2024-06-01` (sekitar separuh index), dan `customer_id = 4211` hanya diperiksa di dalam index pada setiap entri yang dilewati. Buffers **hit=3.821** (sekitar separuh dari 7.692 halaman index). Waktu **58,764 / 14,472 / 14,054 ms**; tercepat **14,054 ms**, median **14,472 ms**. Ukuran index **63.012.864 byte (60 MB)**.

Keluaran : `explain/q08_salah.txt`, `explain/q08_ddl.txt`
```
Limit  (cost=0.43..25310.30 rows=17 width=22) (actual time=0.166..14.025 rows=13 loops=1)
  Buffers: shared hit=3821
  ->  Index Scan Backward using ev_salah_idx on event_log  (actual time=0.165..14.015 rows=13 loops=1)
        Index Cond: ((terjadi_pada >= '2024-05-31 17:00:00+00') AND (customer_id = 4211))
        Buffers: shared hit=3821
Execution Time: 14.054 ms
```

### Q9
Hapus index salah, buat ev_benar_idx (customer_id, terjadi_pada DESC), lalu bandingkan tiga waktu dalam satu tabel.
>> Dengan `ev_benar_idx`, rencana menjadi **Index Scan using ev_benar_idx** dengan Index Cond `customer_id = 4211 AND terjadi_pada >= ...`, tanpa node Sort. Kedua kolom menjadi batas pencarian sehingga hanya halaman milik customer 4211 yang disentuh: Buffers turun dari 58.572 (baseline) dan 3.821 (index salah) menjadi **16**. Median **0,075 ms**, sekitar **1.520 kali** lebih cepat dari baseline dan sekitar **193 kali** lebih cepat dari index urutan salah.

| Skenario | Run 1 (ms) | Run 2 (ms) | Run 3 (ms) | Tercepat | Median | Buffers |
| --- | --- | --- | --- | --- | --- | --- |
| Baseline (tanpa index) | 277,249 | 113,970 | 106,967 | 106,967 | 113,970 | 58.572 |
| ev_salah_idx | 58,764 | 14,472 | 14,054 | 14,054 | 14,472 | 3.821 |
| ev_benar_idx | 0,075 | 0,075 | 0,105 | 0,075 | 0,075 | 16 |

Keluaran : `explain/q09_benar.txt`, `explain/q09_ddl.txt`
```
Limit  (cost=0.43..72.76 rows=17 width=22) (actual time=0.015..0.086 rows=13 loops=1)
  Buffers: shared hit=16
  ->  Index Scan using ev_benar_idx on event_log  (actual time=0.014..0.085 rows=13 loops=1)
        Index Cond: ((customer_id = 4211) AND (terjadi_pada >= '2024-05-31 17:00:00+00'))
        Buffers: shared hit=16
Execution Time: 0.105 ms
```

### Q10
Bandingkan ukuran ev_salah_idx dan ev_benar_idx. Jelaskan mengapa kolom yang sama dapat menghasilkan ukuran berbeda.
>> `ev_salah_idx` = **63.012.864 byte (7.692 halaman, 60 MB)**, `ev_benar_idx` = **63.102.976 byte (7.703 halaman, 60 MB)**; selisih **90.112 byte (11 halaman), 0,14%**. Praktis keduanya sama besar. Kedua index memuat 2.000.000 entri dari kolom yang sama (`integer` 4 byte dan `timestamptz` 8 byte) sehingga lebar entrinya sama: header IndexTuple 8 byte + 4 + 8 byte dengan padding alignment menjadi 24 byte, ditambah line pointer 4 byte = 28 byte per entri. Dengan fillfactor daun 90% angkanya menjadi sekitar 31,1 byte per entri, mendekati hasil ukur **31,51** dan **31,55 byte/entri** (sisanya header halaman dan halaman internal). Urutan kolom dan arah `DESC` tidak mengubah lebar entri. Selisih 11 halaman kemungkinan berasal dari halaman internal dan cara halaman daun dibagi saat index dibangun; penyebab pastinya tidak kami ukur (butuh `pageinspect`). Kesimpulannya, urutan kolom hampir tidak memengaruhi ukuran, tetapi sangat memengaruhi kegunaan index (Q9: 3.821 vs 16 buffers).

Keluaran : `explain/q10_ddl.txt`

### Q11 (Reflektif)
Kaitkan urutan daun B-Tree dengan kemampuan optimizer berhenti mengurutkan hasil.
>> Daun B-Tree menyimpan entri terurut menurut `(customer_id, terjadi_pada DESC)`. Untuk `customer_id = 4211`, semua entri milik customer itu berdampingan dan sudah menurun menurut `terjadi_pada`, persis seperti `ORDER BY terjadi_pada DESC`, sehingga optimizer tidak memerlukan node Sort. Pada data kami hanya **13** baris yang lolos filter (di bawah `LIMIT 20`), jadi `LIMIT` belum sempat memotong pemindaian; keuntungan yang terukur adalah hilangnya Sort dan turunnya Buffers dari 58.572 menjadi **16**. Pada `ev_salah_idx` Sort juga hilang karena daunnya terurut menurut `terjadi_pada`, tetapi entri milik satu customer tersebar di seluruh daun, sehingga pemindaian harus melewati sekitar separuh index (3.821 buffers). Jadi bebas dari Sort belum cukup: kolom yang diuji kesamaan harus berada di depan agar entri yang relevan berdampingan.

### Q12
Bandingkan ukuran ev_gagal_idx dan index polos pada terjadi_pada. Hitung persentase penghematan.
>> Index polos `ev_terjadi_plain_idx` = **44.949.504 byte (43 MB)**; index parsial `ev_gagal_idx` = **917.504 byte (896 kB)**. Penghematan = (44.949.504 − 917.504) / 44.949.504 × 100 = **97,96%**. Index parsial hanya memuat baris `status = 'GAGAL'`, yaitu **40.000** dari 2.000.000 baris (**2,00%**).

Keluaran : `explain/q12_ddl.txt`

### Q13
Bandingkan query email = ... dengan lower(email) = .... Index mana yang dipakai?
>> `email = 'user1234567@contoh.ac.id'` **tidak dapat memakai** `ev_email_lower_idx` karena index dibangun atas ekspresi `lower(email)`, bukan `email`: rencana **Seq Scan**, Rows Removed by Filter 1.999.999, Buffers hit=12.815 read=45.754 (58.569 halaman), tercepat **131,429 ms**, median **136,236 ms**. `lower(email) = '...'` **memakai Index Scan using ev_email_lower_idx**, Buffers **hit=4**, tercepat **0,061 ms**, median **0,071 ms**, sekitar **1.900 kali** lebih cepat. Ekspresi di query harus sama persis dengan ekspresi pada definisi index. Biayanya ukuran index **86 MB**. Index dibangun lalu `ANALYZE` dijalankan, sehingga estimasi baris menjadi 1; tanpa statistik ekspresi, percobaan awal kami (sebelum index ada) memperkirakan 10.000 baris.

Keluaran : `explain/q13_email_polos.txt`, `explain/q13_email_lower.txt`
```
-- email = ...
Seq Scan on event_log  (cost=0.00..83568.48 rows=1 width=32) (actual time=92.261..147.012 rows=1 loops=1)
  Filter: (email = 'user1234567@contoh.ac.id'::text)
  Rows Removed by Filter: 1999999
  Buffers: shared hit=12815 read=45754
Execution Time: 147.049 ms

-- lower(email) = ...
Index Scan using ev_email_lower_idx on event_log  (cost=0.43..8.45 rows=1 width=32) (actual time=0.019..0.019 rows=1 loops=1)
  Index Cond: (lower(email) = 'user1234567@contoh.ac.id'::text)
  Buffers: shared hit=4
Execution Time: 0.071 ms
```

### Q14
Uji query cakupan sebelum dan sesudah VACUUM (ANALYZE); salin Heap Fetches.
>> Autovacuum biasanya sudah membersihkan tabel setelah pemuatan data, sehingga kondisi "sebelum" dibuat terkontrol: autovacuum dimatikan sementara pada tabel, `VACUUM (ANALYZE)` dijalankan sebagai titik awal (`relallvisible` = 58.569 dari 58.569 halaman), lalu `UPDATE ... SET jumlah = jumlah WHERE customer_id = 4211` (20 baris) mengotori halaman milik customer tersebut. Hasil: **sebelum VACUUM**, Index Only Scan using ev_cover_idx dengan **Heap Fetches: 20**, Buffers **hit=8**, median **0,062 ms**. **Sesudah VACUUM (ANALYZE)**, **Heap Fetches: 0**, Buffers **hit=5**, median **0,062 ms**. Selisih waktu hampir tidak terlihat karena semua halaman sudah ada di cache dan hanya 20 baris; efeknya tampak pada Heap Fetches dan Buffers, dan pada tabel yang tidak ter-cache setiap Heap Fetch dapat berupa pembacaan acak ke disk. Autovacuum dikembalikan dengan `RESET (autovacuum_enabled)` (`reloptions` kembali kosong).

Keluaran : `explain/q14_sebelum_vacuum.txt`, `explain/q14_sesudah_vacuum.txt`
```
-- sebelum VACUUM
Index Only Scan using ev_cover_idx on event_log  (cost=0.43..9.02 rows=34 width=18) (actual time=0.016..0.025 rows=20 loops=1)
  Index Cond: (customer_id = 4211)
  Heap Fetches: 20
  Buffers: shared hit=8

-- sesudah VACUUM (ANALYZE)
Index Only Scan using ev_cover_idx on event_log  (cost=0.43..9.02 rows=34 width=18) (actual time=0.014..0.020 rows=20 loops=1)
  Index Cond: (customer_id = 4211)
  Heap Fetches: 0
  Buffers: shared hit=5
```

### Q15
Ganti index INCLUDE dengan index tiga kolom biasa. Bandingkan ukuran serta rencana eksekusi.
>> `ev_cover_idx` (`customer_id` INCLUDE `terjadi_pada, jumlah`) = **81.133.568 byte (77 MB)**; `ev_tiga_idx` (`customer_id, terjadi_pada, jumlah`) = **81.133.568 byte (77 MB)**, selisih **0%**. Rencana keduanya sama: **Index Only Scan**, Heap Fetches **0**. Buffers **5** (INCLUDE, dari pengukuran sesudah VACUUM Q14) vs **6** (tiga kolom); median **0,062 ms** vs **0,068 ms**; selisih sekecil ini berada pada tingkat noise pengukuran. Ukurannya sama karena entri daun memuat kolom yang sama dalam urutan yang sama; halaman internal hanya sebagian kecil index dan perbedaan lebarnya tidak mengubah jumlah halaman pada data ini. Perbedaan kedua index ada pada kemampuan, bukan ukuran: kolom `terjadi_pada` pada index tiga kolom adalah kolom kunci sehingga dapat dipakai untuk pencarian rentang dan pengurutan (setelah `customer_id`), sedangkan kolom INCLUDE hanya membawa data agar Index-Only Scan tidak perlu ke heap.

Keluaran : `explain/q14_sesudah_vacuum.txt` (INCLUDE), `explain/q15_tiga.txt`, `explain/q15_ddl.txt`
```
Index Only Scan using ev_tiga_idx on event_log  (cost=0.43..9.02 rows=34 width=18) (actual time=0.018..0.020 rows=20 loops=1)
  Index Cond: (customer_id = 4211)
  Heap Fetches: 0
  Buffers: shared hit=6
Execution Time: 0.075 ms
```

### Q16 (Reflektif)
Mengapa Heap Fetches berubah setelah VACUUM walau definisi index tidak berubah?
>> Index-Only Scan hanya boleh melewati heap untuk halaman yang ditandai all-visible pada visibility map; untuk halaman lain PostgreSQL harus mengunjungi heap guna memeriksa apakah tuple terlihat oleh transaksi, dan kunjungan itu dihitung sebagai Heap Fetches. Setelah `UPDATE` pada 20 baris customer 4211, halaman-halaman itu kehilangan tanda all-visible sehingga Heap Fetches = **20** (Buffers 8). VACUUM membersihkan tuple mati dan menandai kembali halaman tersebut sebagai all-visible, sehingga Heap Fetches turun menjadi **0** (Buffers 5) meskipun definisi index tidak berubah. Jadi manfaat covering index bergantung pada kesehatan visibility map, yaitu seberapa rutin VACUUM berjalan, bukan hanya pada definisi index.

### Q22
**Perintah :**
```
CREATE INDEX event_log_status_idx
ON lab6.event_log(status);

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log
WHERE status = 'SUKSES';

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM lab6.event_log
WHERE status = 'GAGAL';
```

**Keluaran :**
```
docker compose exec -T postgres psql -U msbd -d latihan < latihan/p06/q22_sukses.sql
                                                      QUERY PLAN                                                       
-----------------------------------------------------------------------------------------------------------------------
 Seq Scan on event_log  (cost=0.00..83567.15 rows=1673277 width=194) (actual time=0.896..604.962 rows=1680000 loops=1)
   Filter: (status = 'SUKSES'::text)
   Rows Removed by Filter: 320000
   Buffers: shared hit=16232 read=42335
 Planning:
   Buffers: shared hit=145 read=42
 Planning Time: 23.118 ms
 Execution Time: 689.253 ms
(8 rows)


docker compose exec -T postgres psql -U msbd -d latihan < latihan/p06/q22_gagal.sql
  QUERY PLAN                                                               
----------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on event_log  (cost=453.53..56576.19 rows=40400 width=194) (actual time=21.353..246.155 rows=40000 loops=1)
   Recheck Cond: (status = 'GAGAL'::text)
   Heap Blocks: exact=39930
   Buffers: shared read=39966
   ->  Bitmap Index Scan on event_log_status_idx  (cost=0.00..443.43 rows=40400 width=0) (actual time=9.996..9.998 rows=40000 loops=1)
         Index Cond: (status = 'GAGAL'::text)
         Buffers: shared read=36
 Planning:
   Buffers: shared hit=145 read=42
 Planning Time: 1.267 ms
 Execution Time: 250.751 ms
(11 rows)

```

### Q23
**Perintah :**
```
SELECT status, COUNT(*) AS jumlah,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS fraksi_persen
FROM lab6.event_log
GROUP BY status
ORDER BY status;
```

**Keluaran :**
```
docker compose exec -T postgres psql -U msbd -d latihan < latihan/p06/q23_fraksi_status.sql
  status  | jumlah  | fraksi_persen 
----------+---------+---------------
 GAGAL    |   40000 |          2.00
 SUKSES   | 1680000 |         84.00
 TERTUNDA |  280000 |         14.00
(3 rows)
```
---

## Baris untuk "Tabel Perbandingan" (bagian Q7–Q16)
| Query/index | Tercepat | Median | Buffers | Ukuran | Keputusan |
| --- | --- | --- | --- | --- | --- |
| Q7 baseline (tanpa index) | 106,967 ms | 113,970 ms | 58.572 | - | - |
| ev_salah_idx (terjadi_pada, customer_id) | 14,054 ms | 14,472 ms | 3.821 | 60 MB | Dihapus: 3.821 buffers vs 16 pada ev_benar_idx |
| ev_benar_idx (customer_id, terjadi_pada DESC) | 0,075 ms | 0,075 ms | 16 | 60 MB | Dipertahankan: 1.520× lebih cepat dari baseline (usulan: dapat digabung bila ev_tiga_idx dipakai, sebab awalan kolomnya sama) |
| ev_terjadi_plain_idx | - | - | - | 43 MB | Dihapus: 97,96% lebih besar dari versi parsial |
| ev_gagal_idx (parsial GAGAL) | - | - | - | 896 kB | Dipertahankan bila query status GAGAL sering: hanya 2% baris, 896 kB |
| ev_email_lower_idx (lower(email)) | 0,061 ms | 0,071 ms | 4 | 86 MB | Dipertahankan bila ada pencarian email: 136,236 ms turun ke 0,071 ms, biaya 86 MB |
| Q13 email = ... (tanpa index yang cocok) | 131,429 ms | 136,236 ms | 58.569 | - | - |
| ev_cover_idx (INCLUDE) | 0,059 ms | 0,062 ms | 5 | 77 MB | Dihapus (diganti ev_tiga_idx): ukuran dan rencana identik |
| ev_tiga_idx (3 kolom) | 0,056 ms | 0,068 ms | 6 | 77 MB | Dipertahankan: ukuran sama dengan ev_cover_idx, lebih fleksibel untuk rentang/urutan |

## Penggunaan AI dan Verifikasi (bagian Q7–Q16)
- AI (Claude) dipakai untuk menyusun kerangka perintah SQL, skrip pengukuran `ukur.sh` dan `p.sh`, serta draf penjelasan.
- Verifikasi: semua perintah dijalankan sendiri pada PostgreSQL 17.11 di Docker; seluruh angka diambil dari keluaran EXPLAIN pada `explain/`, bukan dari AI. Setiap query dijalankan 3 kali dengan `max_parallel_workers_per_gather = 0` dan BUFFERS. Dugaan awal AI bahwa `ev_salah_idx` tidak akan dipakai ternyata salah menurut hasil kami (index dipakai tetapi memindai separuh index), dan jawaban Q8 kami sesuaikan dengan hasil tersebut.
- Pengukuran awal Q8–Q15 sempat tidak valid karena perintah pembuat index tidak terjalankan akibat fungsi shell yang hilang; seluruh hasil itu dibuang dan Q8–Q15 diukur ulang dari awal.
- Penyimpangan prosedur: kondisi "sebelum VACUUM" pada Q14 dibuat dengan UPDATE terkontrol karena autovacuum sudah membersihkan tabel setelah pemuatan data.

# Langkah 5 · Q17–Q21 (GIN untuk JSONB/Array dan BRIN untuk Waktu)

# Jalankan dari ROOT repo. Salin semua berkas .sql di folder ini ke latihan/p06/ lebih dulu.

set -euo pipefail
P=latihan/p06
bash $P/p.sh -f $P/q16b_buat_index_langkah5.sql
bash $P/p.sh -f $P/q17_ukuran.sql
bash $P/ukur.sh q17_gin_jsonb q17_gin_jsonb.sql
bash $P/ukur.sh q17_tanpa_gin q17_tanpa_gin.sql
bash $P/p.sh -f $P/q18_ukuran.sql
bash $P/ukur.sh q18_gin_tags q18_gin_tags.sql
bash $P/ukur.sh q18_tanpa_gin q18_tanpa_gin.sql
bash $P/p.sh -c "ANALYZE lab6.event_log;"
bash $P/p.sh -f $P/q19_korelasi_ukuran.sql
bash $P/ukur.sh q20_brin q20_brin.sql
bash $P/ukur.sh q20_btree q20_btree.sql

### Q17

Uji `payload @> '{"promo": true}'`. Apakah GIN dipakai dan bagaimana ukurannya dibanding heap?

> > GIN **dipakai**: rencana berupa **Bitmap Index Scan on event_log_payload_idx** lalu **Bitmap Heap Scan** (Recheck Cond `payload @> '{"promo": true}'`), estimasi baris 80.402, nyata **80.000** (4,00% dari 2 juta). Tanpa GIN rencananya Seq Scan (Rows Removed by Filter 1.920.000). Waktu tercepat/median dengan GIN sekitar **266 / 276 ms** dibanding **543 / 555 ms** tanpa GIN (kira-kira 2 kali lebih cepat). Ukuran `event_log_payload_idx` (jsonb_path_ops) = **7.266.304 byte (7.096 kB)**, atau **1,51%** dari heap (**479.797.248 byte, 458 MB**). Keuntungannya hanya sekitar 2 kali karena baris promo (setiap baris ke-25) tersebar merata: dengan ±34 baris per halaman hampir setiap halaman memuat satu baris promo, sehingga Bitmap Heap Scan tetap membaca **semua 58.569 halaman** (`Heap Blocks: exact=58569`). GIN menghemat evaluasi filter jsonb per baris, bukan I/O heap.

Keluaran : `explain/q17_gin_jsonb.txt`, `explain/q17_tanpa_gin.txt`

### Q18

Uji keanggotaan tags dengan `@>`; bandingkan rencana dengan dan tanpa GIN.

> > Query: `tags @> ARRAY['kanal:1','sumber:2']` (**166.667 baris, 8,33%**). Dengan GIN: **Bitmap Index Scan on event_log_tags_idx** + Bitmap Heap Scan (`Heap Blocks: exact=58569`), waktu tercepat/median sekitar **280 / 281 ms**. Tanpa GIN (index dihapus dalam transaksi lalu di-ROLLBACK): **Seq Scan** dengan `Rows Removed by Filter` 1.833.333, sekitar **536 / 548 ms**. Ukuran `event_log_tags_idx` = **4.664 kB** (±1% heap). Pola sama dengan Q17: GIN mempercepat sekitar 2 kali, tetapi karena 8,33% baris tersebar di semua halaman, pembacaan heap tidak berkurang (Buffers ±58,8 ribu vs ±58,6 ribu). GIN paling berguna jika nilai yang dicari langka (sangat selektif) atau elemen yang dicari banyak sehingga irisan hasilnya kecil.

Keluaran : `explain/q18_gin_tags.txt`, `explain/q18_tanpa_gin.txt`

### Q19

Periksa correlation `terjadi_pada` di pg_stats dan bandingkan ukuran BRIN dengan B-Tree pada kolom sama.

> > `pg_stats.correlation` untuk `terjadi_pada` = **1** (urutan fisik baris di heap persis searah dengan nilai kolom, karena data dimasukkan berurutan waktu 13 detik sekali). Ukuran: **BRIN (pages_per_range=128) = 32.768 byte (32 kB, 4 halaman)**, **B-Tree polos = 44.949.504 byte (43 MB, 5.487 halaman)**. BRIN hanya **0,073%** dari ukuran B-Tree (B-Tree **±1.372 kali** lebih besar). BRIN cukup menyimpan satu ringkasan min/max per 128 halaman heap (58.569/128 ≈ 458 rentang), sedangkan B-Tree menyimpan satu entri per baris (2 juta).

Keluaran : `q19_korelasi_ukuran.sql`

### Q20

Uji rentang tujuh hari dengan BRIN dan B-Tree. Catat pemenang serta selisih Buffers.

> > Query: `terjadi_pada >= '2024-03-01 00:00+07' AND < '2024-03-08 00:00+07'` (**46.523 baris**, ±2,3%). BRIN: **Bitmap Index Scan** + Bitmap Heap Scan (**lossy=1.536** blok, Rows Removed by Index Recheck 6.103), Buffers **1.546**, median **±14,3 ms**. B-Tree: **Index Scan using ev_terjadi_plain_idx**, Buffers **1.665**, median **±13,6 ms**. **Pemenang waktu: B-Tree**, tetapi tipis (±0,7 ms, ±5%, mendekati noise). Selisih Buffers: BRIN lebih sedikit **±119 buffers (±7%)**, karena B-Tree harus membaca ±130 halaman index sedangkan BRIN hanya ±10 halaman. Karena correlation = 1, tujuh hari data menempati blok heap yang berdekatan (±1.536 halaman) sehingga BRIN hampir tidak membaca halaman berlebih. Bila kedua index ada, planner memilih B-Tree (cost 2.755 vs 59.071 untuk BRIN).

Keluaran : `explain/q20_brin.txt`, `explain/q20_btree.txt`

### Q21 (Reflektif)

Kapan penghematan ukuran BRIN sepadan dengan selisih waktunya?

> > Pada data kami BRIN menghemat **±43 MB (99,93%)** dengan harga waktu hanya **±0,7 ms (±5%)** pada rentang 7 hari, bahkan Buffers-nya lebih sedikit; jadi penghematan itu **sepadan** bila (1) **correlation mendekati ±1** (data append-only berurutan waktu seperti log, sensor, atau transaksi), sehingga rentang nilai tiap blok sempit dan tidak ada halaman berlebih yang dibaca; (2) query berupa **rentang lebar** (hari hingga bulan) yang memang membaca banyak baris; (3) tabel sangat besar atau penyimpanan/waktu pemeliharaan index penting, karena BRIN murah dibuat dan hampir tanpa biaya saat INSERT. Penghematan **tidak sepadan** bila correlation rendah (data diacak atau sering di-UPDATE/DELETE sehingga urutan fisik rusak; BRIN memindai banyak blok lossy), bila query berupa **pencarian titik atau rentang sangat sempit** (B-Tree hanya menyentuh beberapa halaman, BRIN tetap membaca seluruh blok dalam rentang 128 halaman), atau bila butuh ORDER BY/LIMIT atau Index-Only Scan yang tidak dapat dilayani BRIN. Catatan: `pages_per_range` yang lebih kecil membuat BRIN lebih presisi tetapi lebih besar.

## Baris untuk "Tabel Perbandingan" (bagian Q17–Q21)

| Query/index                                            | Tercepat   | Median     | Buffers | Ukuran   | Keputusan                                                                                                                                                                                                        |
| ------------------------------------------------------ | ---------- | ---------- | ------- | -------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Q17 payload @> ... tanpa GIN (Seq Scan)                | 542,875 ms | 555,418 ms | 58.569  | -        | -                                                                                                                                                                                                                |
| event_log_payload_idx (GIN jsonb_path_ops)             | 266,430 ms | 275,803 ms | 58.590  | 7.096 kB | Dipertahankan bila filter @> pada payload sering dipakai: sekitar 2× lebih cepat, biaya hanya 1,51% dari heap. Peningkatannya kecil karena 4% baris tersebar di semua halaman (58.569 halaman heap tetap dibaca) |
| Q18 tags @> ... tanpa GIN (Seq Scan)                   | 535,544 ms | 548,047 ms | 58.576  | -        | -                                                                                                                                                                                                                |
| event_log_tags_idx (GIN)                               | 279,292 ms | 281,271 ms | 58.809  | 4.664 kB | Dipertahankan bila nilai yang dicari selektif; untuk nilai yang cocok dengan 8,33% baris keuntungannya hanya sekitar 2×                                                                                          |
| event_log_terjadi_pada_idx (BRIN, 128 halaman/rentang) | 13,927 ms  | 14,318 ms  | 1.546   | 32 kB    | Dipertahankan: correlation = 1, ukuran hanya 0,073% dari B-Tree, selisih waktu sekitar 0,7 ms                                                                                                                    |
| ev_terjadi_plain_idx (B-Tree, rentang 7 hari)          | 13,277 ms  | 13,624 ms  | 1.665   | 43 MB    | Dihapus bila hanya untuk rentang waktu (BRIN sudah cukup); dipertahankan bila perlu ORDER BY/LIMIT atau pencarian titik                                                                                          |

## Penggunaan AI dan Verifikasi (bagian Q17–Q21)

- AI (Claude) dipakai untuk menyusun berkas SQL (`q17_*` sampai `q20_*`), skrip `jalankan_langkah5.sh`, dan draf penjelasan Q17–Q21.
- Verifikasi: [ISI: semua perintah dijalankan sendiri pada PostgreSQL 17.x di Docker; seluruh angka diambil dari `explain/` dan `hasil_pengukuran_q07_q16.md`, bukan dari AI.] Setiap query dijalankan 3 kali dengan `max_parallel_workers_per_gather = 0` dan BUFFERS.
- Draf angka dari AI divalidasi pada PostgreSQL 16 dengan data yang sama, lalu diganti dengan hasil ukur kami: [ISI: bagian yang berbeda dari draf dan bagaimana jawabannya disesuaikan].
- Pengukuran "tanpa GIN" dan "BRIN vs B-Tree" memakai `DROP INDEX` di dalam transaksi yang di-ROLLBACK, sehingga index tidak hilang permanen. Query Q17 dan Q18 memakai `@>` dengan nilai `{"promo": true}` dan `ARRAY['kanal:1','sumber:2']`.


# Langkah 7 · Q27–Q31

### Q27
Bandingkan INSERT 200000 baris pada tabel tanpa index dan dengan lima index. Nyatakan selisih waktu dalam persen.
>Membandingkan waktu INSERT 200.000 baris pada tabel tanpa index dan tabel dengan lima index. Berdasarkan konsep pengukuran, tabel dengan lima index akan memiliki pekerjaan tambahan karena setiap baris yang dimasukkan juga harus dicatat ke struktur index. Persentase selisih waktu dihitung menggunakan perbedaan median waktu kedua kondisi. Nilai waktu dan persentase akhir harus diambil dari tiga kali eksekusi PostgreSQL sesuai aturan praktikum.

Format hasil:
Kondisi	Percobaan 1	Percobaan 2	Percobaan 3	Median
Tanpa index	1134.556 ms	905.741 ms	897.909 ms	979.402 ms
5 index	1784.022 ms	1774.872 ms	1760.472 ms	1773.122 ms

Selisih (%) =
((1773.122 - 979.402)
 / 979.402) × 100%
 Hasilnya = 81.04%


 ### Q28
Bandingkan ukuran total tabel pada kedua keadaan.
>Membandingkan ukuran total tabel pada kondisi tanpa index dan dengan lima index. Tabel dengan lima index dapat memiliki ukuran total lebih besar karena index membutuhkan ruang penyimpanan tambahan. Pengukuran dilakukan menggunakan pg_total_relation_size() sehingga ukuran tabel beserta objek penyimpanan terkait dapat dibandingkan.

kondisi     | ukuran_total 
----------------+--------------
 Tanpa index    | 30 MB
 Dengan 5 index | 51 MB
(2 rows)

Time: 3.346 ms


### Q29
Daftar seluruh index lab6, idx_scan, dan ukuran. Tentukan index dengan idx_scan nol serta alasan jika tetap harus dipertahankan.
>Seluruh index pada schema lab6 diperiksa melalui pg_stat_user_indexes. Kolom idx_scan digunakan untuk melihat frekuensi penggunaan setiap index, sedangkan ukuran index diperoleh menggunakan pg_relation_size(). Index dengan idx_scan = 0 tidak langsung berarti harus dihapus karena index tersebut mungkin belum digunakan selama workload pengujian atau masih diperlukan untuk query tertentu.

tabel      |    nama_index    | idx_scan |   ukuran   
----------------+------------------+----------+------------
 event_log      | event_log_pkey   |        0 | 8192 bytes
 event_log_5idx | q27_idx_customer |        0 | 3808 kB
 event_log_5idx | q27_idx_email    |        0 | 14 MB
 event_log_5idx | q27_idx_status   |        0 | 1272 kB
 event_log_5idx | q27_idx_waktu    |        0 | 1272 kB
 event_log_5idx | q27_idx_wilayah  |        0 | 1272 kB
(6 rows)

Time: 3.376 ms


### Q30
Susun rekomendasi final: index dipertahankan, dihapus, dan digabung—masing-masing disertai satu angka pengukuran.
>Rekomendasi index dibuat berdasarkan gabungan hasil pengukuran waktu eksekusi, Buffers, ukuran index, dan idx_scan. Index yang memberikan keuntungan nyata terhadap query dan masih digunakan dapat dipertahankan, sedangkan index yang tidak memberikan manfaat dan memiliki biaya penyimpanan atau penulisan dapat dipertimbangkan untuk dihapus. Jika terdapat index dengan fungsi yang tumpang tindih, penggabungan atau penyederhanaan index dapat dipertimbangkan.

nama_index    |   ukuran   | idx_scan      | keputusan
------------------+------------+-------------------------
 q27_idx_email    | 14 MB      |        0 | Hapus
 q27_idx_customer | 3808 kB    |        0 | Gabung
 q27_idx_waktu    | 1272 kB    |        0 | Pertahankan
 q27_idx_status   | 1272 kB    |        0 | Pertahankan
 q27_idx_wilayah  | 1272 kB    |        0 | Pertahankan
 event_log_pkey   | 8192 bytes |        0 | Pertahankan
(6 rows)

Time: 13.414 ms


### Q31
Untuk setiap index yang direkomendasikan dihapus atau dipertahankan, sebutkan satu angka sebagai dasar keputusan.
>Dasar pengambilan keputusan pada tahap ini adalah hasil pengukuran biaya INSERT, ukuran storage, dan statistik penggunaan index. Median waktu INSERT tanpa index adalah 979,402 ms, sedangkan dengan 5 index adalah 1773,122 ms, sehingga penggunaan 5 index meningkatkan waktu INSERT sekitar 81,04%. Dari sisi storage, tabel tanpa index berukuran 30 MB, sedangkan tabel dengan 5 index berukuran 51 MB, sehingga terdapat tambahan penggunaan storage sebesar 21 MB atau 70%. Sementara itu, seluruh index yang diuji memiliki idx_scan = 0. Karena belum dilakukan pengujian query SELECT yang memanfaatkan index tersebut, hasil idx_scan = 0 digunakan sebagai dasar evaluasi, bukan sebagai alasan langsung untuk menghapus seluruh index.