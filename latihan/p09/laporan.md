# Laporan Latihan Kelompok Pertemuan 9

| Nama                   | NIM       | Kontribusi                    |
| ---------------------- | --------- | ----------------------------- |
| Agnes Natalia Siregar  | 251402108 |  |
| Abdullah Zufar Aulia   | 251402111 |  |
| Rasyd Arija A. Ritonga | 251402020 |  |
| Dwi Charima Husni      | 251402088 |  |
| Fakhry Adrian Daulay   | 251402053 |  |

## Jawaban Q1–Q32
### Q1
Buktikan kondisi awal dan jumlah saldo keseluruhan.
>> Data awal memuat saldo masing-masing sebesar Rp1.000.000 untuk Ani dan Budi sehingga total keseluruhan saldo di awal adalah Rp2.000.000.
AGNES@LAPTOP-1T3ANVB7 MINGW64 /c/Semester 3/msbd-2026 (latihan/p09-transaksi-konkurensi)
$ docker exec -i msbd-pg psql -U msbd -d pagila < latihan/p09/q01_q32_transaksi.sql
 rekening_id | pemilik |   saldo    
-------------+---------+------------
           1 | Ani     | 1000000.00
           2 | Budi    | 1000000.00
(2 rows)

 total_saldo 
-------------
  2000000.00
(1 row)

### Q2
Jalankan BEGIN, ubah saldo, lalu periksa hasil sebelum COMMIT. Apa yang terlihat di sesi lain?
>> Di Sesi A: Saldo Ani berubah menjadi 800000.00, Budi tetap 1000000.00.
Di Sesi B: Saldo Ani masih tetap 1000000.00 dan Budi 1000000.00 (belum berubah).
Status: Transaksi aktif di Sesi A (belum COMMIT / ROLLBACK).
Terjadi karena penerapan aturan Isolation (khususnya tingkat Read Committed default PostgreSQL). Perubahan data yang dilakukan dalam satu transaksi aktif (BEGIN) di Sesi A tidak akan terlihat oleh sesi lain (Sesi B) sebelum transaksi tersebut di-commit secara permanen. Hal ini mencegah dirty read.

AGNES@LAPTOP-1T3ANVB7 MINGW64 /c/Semester 3/msbd-2026 (latihan/p09-transaksi-konkurensi)
$ docker exec -i msbd-pg psql -U msbd -d pagila < latihan/p09/q01_q32_transaksi.sql
BEGIN
UPDATE 1
 rekening_id | pemilik |   saldo    
-------------+---------+------------
           1 | Ani     |  800000.00
           2 | Budi    | 1000000.00
(2 rows)

 rekening_id | pemilik |   saldo    
-------------+---------+------------
           1 | Ani     |  800000.00
           2 | Budi    | 1000000.00
(2 rows)

### Q3
Bandingkan COMMIT dan ROLLBACK. Perubahan mana yang bertahan?
>> Setelah COMMIT, perubahan saldo Budi permanen tersimpan di database dan bisa dilihat oleh sesi lain.
Setelah ROLLBACK, saldo Budi kembali seperti semula sebelum blok BEGIN dijalankan.
Status: COMMIT (Permanen), ROLLBACK (Dibatalkan).
Perintah COMMIT mengakhiri transaksi dan menyimpan semua perubahan secara permanen ke dalam basis data. Sebaliknya, perintah ROLLBACK membatalkan seluruh perubahan yang dilakukan selama transaksi berlangsung dan mengembalikan kondisi data ke keadaan semula sebelum transaksi dimulai.

AGNES@LAPTOP-1T3ANVB7 MINGW64 /c/Semester 3/msbd-2026 (latihan/p09-transaksi-konkurensi)
$ docker exec -i msbd-pg psql -U msbd -d pagila < latihan/p09/q01_q32_transaksi.sql
BEGIN
WARNING:  there is already a transaction in progress
UPDATE 1
COMMIT
 rekening_id | pemilik |   saldo    
-------------+---------+------------
           1 | Ani     |  800000.00
           2 | Budi    | 1100000.00
(2 rows)

BEGIN
UPDATE 1
ROLLBACK
 rekening_id | pemilik |   saldo    
-------------+---------+------------
           1 | Ani     |  800000.00
           2 | Budi    | 1100000.00
(2 rows)


### Q4
Buat transaksi dengan SAVEPOINT, ubah saldo, lalu jalankan ROLLBACK TO SAVEPOINT. Bagian mana yang dibatalkan?
>> Hasil SELECT: Saldo Ani hanya bertambah 50.000 dari Perubahan 1, sementara penambahan 500.000 dari Perubahan 2 dibatalkan.
Status: Berhasil di-rollback sebagian ke sp_satu.
Perintah ROLLBACK TO SAVEPOINT hanya membatalkan pernyataan SQL yang dieksekusi setelah titik penanda (SAVEPOINT) tersebut dibuat. Perubahan yang terjadi sebelum SAVEPOINT tetap aman dan dipertahankan di dalam transaksi.

AGNES@LAPTOP-1T3ANVB7 MINGW64 /c/Semester 3/msbd-2026 (latihan/p09-transaksi-konkurensi)
$ docker exec -i msbd-pg psql -U msbd -d pagila < latihan/p09/q01_q32_transaksi.sql
BEGIN
UPDATE 1
SAVEPOINT
UPDATE 1
ROLLBACK
 rekening_id | pemilik |   saldo    
-------------+---------+------------
           1 | Ani     |  850000.00
           2 | Budi    | 1100000.00
(2 rows)

COMMIT

### Q5
Jelaskan bagaimana atomicity dan consistency didukung oleh transaksi dan constraint CHECK.
>> Atomicity (Atomisitas): Didukung penuh oleh mekanisme transaksi (BEGIN, COMMIT, ROLLBACK). Prinsip ini memastikan bahwa seluruh rangkaian perintah di dalam blok transaksi diperlakukan sebagai satu kesatuan utuh (all-or-nothing). Jika ada satu saja perintah yang gagal di tengah jalan, seluruh perubahan akan dibatalkan (rollback) sehingga tidak ada data setengah jadi yang tersimpan.
Consistency (Konsistensi): Didukung oleh kombinasi transaksi dan aturan constraint (seperti PRIMARY KEY dan CHECK (saldo >= 0) yang kita buat di awal). Constraint berfungsi sebagai penjaga aturan integritas data agar database selalu berada dalam kondisi valid. Jika ada transaksi yang mencoba melanggar aturan (misalnya memaksa saldo menjadi negatif), transaksi tersebut akan ditolak oleh sistem dan dibatalkan, sehingga konsistensi data tetap terjaga.

### Q6
Pada READ COMMITTED, Sesi A menjalankan BEGIN lalu SELECT saldo rekening 1. Sesi B mengubah saldo rekening 1 dan COMMIT. Sesi A menjalankan SELECT yang sama lagi. Apakah hasil kedua pembacaan berubah?
>> Ya, berubah. Pembacaan pertama di Sesi A = 1000000.00, pembacaan kedua (setelah Sesi B COMMIT) = 1100000.00.
Status: terjadi non-repeatable read.
Pada READ COMMITTED (default PostgreSQL), setiap statement SELECT memakai snapshot baru. Perubahan Sesi B yang sudah di-COMMIT langsung terlihat oleh SELECT berikutnya di Sesi A, walaupun Sesi A masih berada di transaksi yang sama. Akibatnya dua SELECT identik dalam satu transaksi bisa memberi hasil berbeda.

<!-- GANTI dengan output terminal kalian dari 2 terminal (Sesi A dan Sesi B) -->
```
## Sesi A
pagila=# BEGIN;
pagila=*# SHOW transaction_isolation;
 transaction_isolation
-----------------------
 read committed

pagila=*# SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;
 rekening_id |   saldo
-------------+------------
           1 | 1000000.00

## Sesi B
pagila=# UPDATE lab9.rekening SET saldo = saldo + 100000 WHERE rekening_id = 1;
UPDATE 1
pagila=# SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;
 rekening_id |   saldo
-------------+------------
           1 | 1100000.00

## Sesi A (ulang)
pagila=*# SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;
 rekening_id |   saldo
-------------+------------
           1 | 1100000.00
pagila=*# COMMIT;
```

### Q7
Ulangi Q6 dengan REPEATABLE READ. Jelaskan perbedaan hasilnya dengan READ COMMITTED.
>> Pada REPEATABLE READ, pembacaan kedua di Sesi A tetap 1000000.00 walaupun Sesi B sudah mengubah menjadi 1100000.00 dan COMMIT. Nilai baru baru terlihat setelah Sesi A selesai (COMMIT), yaitu 1100000.00.
Status: tidak terjadi non-repeatable read.

| Isolation level | Baca 1 (Sesi A) | Baca 2 (Sesi A, setelah Sesi B COMMIT) | Berubah? |
| --- | --- | --- | --- |
| READ COMMITTED | 1000000.00 | 1100000.00 | Ya |
| REPEATABLE READ | 1000000.00 | 1000000.00 | Tidak |

REPEATABLE READ di PostgreSQL memakai satu snapshot yang diambil pada query pertama dalam transaksi dan dipakai sampai transaksi berakhir, sehingga perubahan sesi lain yang di-COMMIT tidak terlihat. Pada READ COMMITTED snapshot dibuat ulang untuk setiap statement.

<!-- GANTI dengan output terminal kalian dari 2 terminal (Sesi A dan Sesi B) -->
```
## Sesi A
pagila=# BEGIN ISOLATION LEVEL REPEATABLE READ;
pagila=*# SHOW transaction_isolation;
 transaction_isolation
-----------------------
 repeatable read

pagila=*# SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;
 rekening_id |   saldo
-------------+------------
           1 | 1000000.00

## Sesi B
pagila=# UPDATE lab9.rekening SET saldo = saldo + 100000 WHERE rekening_id = 1;
UPDATE 1

## Sesi A (ulang, masih dalam transaksi)
pagila=*# SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;
 rekening_id |   saldo
-------------+------------
           1 | 1000000.00
pagila=*# COMMIT;

## Sesi A (setelah COMMIT)
pagila=# SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;
 rekening_id |   saldo
-------------+------------
           1 | 1100000.00
```

### Q8
Buat tabel eksperimen berisi beberapa baris. Sesi A menghitung baris dengan saldo di atas nilai tertentu. Sesi B memasukkan baris yang memenuhi kondisi dan COMMIT. Ulangi SELECT di Sesi A pada READ COMMITTED dan REPEATABLE READ; bandingkan jumlahnya.
>> Tabel `lab9.eksperimen_phantom` berisi Cici (500000), Dedi (1500000), Eka (2000000). Kondisi: saldo > 1000000, jumlah awal = 2.
READ COMMITTED: jumlah berubah dari 2 menjadi 3 setelah Sesi B menyisipkan 'Fani' (3000000) dan COMMIT.
REPEATABLE READ: jumlah tetap 2 setelah Sesi B menyisipkan 'Gani' (3500000) dan COMMIT; baru menjadi 3 setelah Sesi A COMMIT.
Status: phantom read terjadi pada READ COMMITTED, tidak terjadi pada REPEATABLE READ.

| Isolation level | Count sebelum | Count sesudah Sesi B INSERT + COMMIT | Phantom? |
| --- | --- | --- | --- |
| READ COMMITTED | 2 | 3 | Ya |
| REPEATABLE READ | 2 | 2 | Tidak |

Baris baru yang memenuhi kondisi WHERE muncul sebagai "hantu" di tengah transaksi pada READ COMMITTED karena snapshot diperbarui tiap statement. Pada REPEATABLE READ snapshot tetap, sehingga baris baru tidak terlihat. Standar SQL sebenarnya masih mengizinkan phantom pada REPEATABLE READ, tetapi implementasi snapshot PostgreSQL mencegahnya.

<!-- GANTI dengan output terminal kalian dari 2 terminal (Sesi A dan Sesi B) -->
```
## Setup
 id | nama |   saldo
----+------+------------
  1 | Cici |  500000.00
  2 | Dedi | 1500000.00
  3 | Eka  | 2000000.00

## 8a READ COMMITTED - Sesi A
pagila=# BEGIN;
pagila=*# SELECT COUNT(*) FROM lab9.eksperimen_phantom WHERE saldo > 1000000;
 count
-------
     2

## Sesi B
pagila=# INSERT INTO lab9.eksperimen_phantom (nama, saldo) VALUES ('Fani', 3000000);
INSERT 0 1

## Sesi A (ulang)
pagila=*# SELECT COUNT(*) FROM lab9.eksperimen_phantom WHERE saldo > 1000000;
 count
-------
     3
pagila=*# COMMIT;

## 8b REPEATABLE READ - Sesi A  (setelah baris Fani dihapus)
pagila=# BEGIN ISOLATION LEVEL REPEATABLE READ;
pagila=*# SELECT COUNT(*) FROM lab9.eksperimen_phantom WHERE saldo > 1000000;
 count
-------
     2

## Sesi B
pagila=# INSERT INTO lab9.eksperimen_phantom (nama, saldo) VALUES ('Gani', 3500000);
INSERT 0 1

## Sesi A (ulang, masih dalam transaksi)
pagila=*# SELECT COUNT(*) FROM lab9.eksperimen_phantom WHERE saldo > 1000000;
 count
-------
     2
pagila=*# COMMIT;

## Sesi A (setelah COMMIT)
pagila=# SELECT COUNT(*) FROM lab9.eksperimen_phantom WHERE saldo > 1000000;
 count
-------
     3
```

### Q9
Di Sesi A ubah saldo tanpa COMMIT. Di Sesi B coba SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED dan baca saldo tersebut. Apakah PostgreSQL menampilkan perubahan yang belum di-commit? Jelaskan perilaku READ UNCOMMITTED di PostgreSQL.
>> Tidak. Sesi A mengubah saldo Ani menjadi 700000.00 (belum COMMIT), tetapi Sesi B (READ UNCOMMITTED) tetap membaca 1000000.00. Setelah Sesi A ROLLBACK, saldo tetap 1000000.00.
Status: dirty read tidak terjadi.
PostgreSQL menerima sintaks READ UNCOMMITTED, tetapi memperlakukannya sama dengan READ COMMITTED. Jadi sesi lain hanya bisa membaca data yang sudah di-COMMIT, dan dirty read tidak pernah terjadi pada level isolasi apa pun di PostgreSQL. Catatan: `SET TRANSACTION ISOLATION LEVEL` harus dijalankan di dalam transaksi (setelah BEGIN) dan sebelum query pertama.

<!-- GANTI dengan output terminal kalian dari 2 terminal (Sesi A dan Sesi B) -->
```
## Sesi A
pagila=# BEGIN;
pagila=*# UPDATE lab9.rekening SET saldo = saldo - 300000 WHERE rekening_id = 1;
UPDATE 1
pagila=*# SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;
 rekening_id |   saldo
-------------+-----------
           1 | 700000.00

## Sesi B
pagila=# BEGIN;
pagila=*# SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
pagila=*# SHOW transaction_isolation;
 transaction_isolation
-----------------------
 read uncommitted

pagila=*# SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;
 rekening_id |   saldo
-------------+------------
           1 | 1000000.00
pagila=*# COMMIT;

## Sesi A
pagila=*# ROLLBACK;
pagila=# SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;
 rekening_id |   saldo
-------------+------------
           1 | 1000000.00
```

### Q10
Kedua sesi membaca saldo yang sama. Masing-masing menghitung saldo baru di sisi aplikasi dan menulis nilai tetap berdasarkan nilai yang dibaca. Tunjukkan bagaimana pembaruan satu sesi dapat menimpa hasil sesi lain.
>> Kedua sesi membaca saldo 1000000.00. Sesi A ingin menambah 100000 (menulis 1100000) dan COMMIT. Sesi B ingin menambah 200000 (menulis 1200000) dan COMMIT. Saldo akhir = 1200000.00, padahal seharusnya 1300000.00.
Status: terjadi lost update, tambahan 100000 dari Sesi A hilang.
Sesi B menulis nilai yang dihitung dari bacaan lama (1000000), bukan dari nilai terbaru setelah Sesi A COMMIT, sehingga menimpa hasil Sesi A. Pencegahan: gunakan update atomik `saldo = saldo + x` sehingga database menghitung dari nilai terbaru. Dengan cara ini saldo akhir = 1300000.00.

<!-- GANTI dengan output terminal kalian dari 2 terminal (Sesi A dan Sesi B) -->
```
## Sesi A
pagila=# BEGIN;
pagila=*# SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;
   saldo
------------
 1000000.00

## Sesi B
pagila=# BEGIN;
pagila=*# SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;
   saldo
------------
 1000000.00

## Sesi A
pagila=*# UPDATE lab9.rekening SET saldo = 1100000 WHERE rekening_id = 1;
UPDATE 1
pagila=*# COMMIT;

## Sesi B
pagila=*# UPDATE lab9.rekening SET saldo = 1200000 WHERE rekening_id = 1;
UPDATE 1
pagila=*# COMMIT;

## Hasil
pagila=# SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;
   saldo
------------
 1200000.00

## Pencegahan (update atomik)
pagila=# UPDATE lab9.rekening SET saldo = 1000000 WHERE rekening_id = 1;
pagila=# UPDATE lab9.rekening SET saldo = saldo + 100000 WHERE rekening_id = 1;  -- Sesi A
pagila=# UPDATE lab9.rekening SET saldo = saldo + 200000 WHERE rekening_id = 1;  -- Sesi B
pagila=# SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;
   saldo
------------
 1300000.00
```

### Q11
Buat tabel ringkas: anomali, urutan kejadian, isolation level, hasil yang diamati, dan cara mencegah atau menangani masalah.
di file Q11_table_ringkasan.md