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