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