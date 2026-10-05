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