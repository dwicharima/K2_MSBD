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

### Q12
Perbaiki lost update menggunakan pembaruan atomik. Jelaskan mengapa menghitung berdasarkan nilai kolom di database lebih aman daripada menulis nilai hasil hitung lama.
>> Cara lama (SET saldo = 990000 dari bacaan SELECT) menghasilkan saldo akhir 990000.00 padahal dua penarikan 10000 seharusnya 980000.00 (lost update). Dengan UPDATE ... SET saldo = saldo - 10000 WHERE rekening_id = 1 AND saldo >= 10000, Sesi B menunggu Sesi A COMMIT, lalu saldo akhir 980000.00 (benar). Pada skenario saldo 15000, Sesi B mendapat UPDATE 0 sehingga saldo tidak pernah negatif.
Status: lost update tercegah.
Menulis nilai hasil hitung lama berarti memakai snapshot data yang sudah basi: aplikasi membaca di waktu T1 tetapi menulis di T2, dan perubahan sesi lain di antara T1-T2 tertimpa. Pada update atomik, perhitungan dilakukan di dalam database pada baris yang sedang di-lock, jadi memakai nilai terbaru yang sudah di-COMMIT. Setelah lock dilepas, PostgreSQL (READ COMMITTED) mengevaluasi ulang klausa WHERE pada versi baris terbaru sehingga pemeriksaan "saldo cukup" dan pengurangan terjadi dalam satu pernyataan tanpa celah check-then-act. CHECK (saldo >= 0) menjadi pagar terakhir.

**12a. Pembanding: menulis nilai hasil hitung lama (lost update)**
```
## Sesi A
pagila=# BEGIN;
pagila=*# SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;
 rekening_id |   saldo
-------------+------------
           1 | 1000000.00

## Sesi B
pagila=# BEGIN;
pagila=*# SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;
 rekening_id |   saldo
-------------+------------
           1 | 1000000.00

## Sesi A
pagila=*# UPDATE lab9.rekening SET saldo = 990000 WHERE rekening_id = 1;
UPDATE 1
pagila=*# COMMIT;
COMMIT

## Sesi B
pagila=*# UPDATE lab9.rekening SET saldo = 990000 WHERE rekening_id = 1;
UPDATE 1
pagila=*# COMMIT;
COMMIT

## Hasil
pagila=# SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;
 rekening_id |   saldo
-------------+-----------
           1 | 990000.00
```
Saldo akhir 990000.00, seharusnya 980000.00 (satu penarikan hilang).

**12b. Perbaikan: pembaruan atomik**
```
## Sesi A
pagila=# BEGIN;
pagila=*# UPDATE lab9.rekening SET saldo = saldo - 10000 WHERE rekening_id = 1 AND saldo >= 10000;
UPDATE 1

## Sesi B
pagila=# BEGIN;
pagila=*# UPDATE lab9.rekening SET saldo = saldo - 10000 WHERE rekening_id = 1 AND saldo >= 10000;

## Sesi A
pagila=*# COMMIT;
COMMIT

## Sesi B (setelah Sesi A COMMIT)
UPDATE 1
pagila=*# COMMIT;
COMMIT

## Hasil
pagila=# SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;
 rekening_id |   saldo
-------------+-----------
           1 | 980000.00
```

**12c. Saldo tidak cukup (klausa WHERE sebagai penjaga)**
```
## Sesi A
pagila=# UPDATE lab9.rekening SET saldo = 15000 WHERE rekening_id = 1;
UPDATE 1
pagila=# BEGIN;
pagila=*# UPDATE lab9.rekening SET saldo = saldo - 10000 WHERE rekening_id = 1 AND saldo >= 10000;
UPDATE 1

## Sesi B
pagila=# BEGIN;
pagila=*# UPDATE lab9.rekening SET saldo = saldo - 10000 WHERE rekening_id = 1 AND saldo >= 10000;

## Sesi A
pagila=*# COMMIT;
COMMIT

## Sesi B
UPDATE 0
pagila=*# COMMIT;
COMMIT

## Hasil
pagila=# SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;
 rekening_id |  saldo
-------------+---------
           1 | 5000.00
```
Sesi B mendapat UPDATE 0, saldo tidak negatif.

### Q13
Ulangi skenario menggunakan SELECT ... FOR UPDATE. Catat kapan sesi kedua menunggu dan apa yang terjadi setelah transaksi pertama selesai.
>> Sesi A menjalankan SELECT ... FOR UPDATE pada rekening 1 dan langsung mendapat 1000000.00. Sesi B menjalankan perintah yang sama dan tertahan menunggu; query Pengamat pada pg_stat_activity menunjukkan Sesi B: wait_event_type = Lock, wait_event = transactionid, diblokir oleh Sesi A. Setelah Sesi A UPDATE 990000 lalu COMMIT, Sesi B dilepas dan membaca 990000.00 (nilai terbaru, bukan 1000000.00). Sesi B menulis 980000 lalu COMMIT. Saldo akhir 980000.00.
Status: lost update tercegah; Sesi B menunggu hingga Sesi A COMMIT.
FOR UPDATE mengunci baris saat dibaca, sehingga pola baca-hitung-tulis dipaksa berjalan bergiliran. Berbeda dengan Q10, Sesi B tidak pernah memegang bacaan lama karena bacaannya sendiri tertahan sampai Sesi A selesai, dan setelah dilepas ia membaca nilai terbaru yang sudah di-COMMIT. Harganya: sesi kedua menganggur selama lock ditahan, jadi transaksi yang memakai FOR UPDATE harus dibuat singkat.

```
## Sesi A
pagila=# BEGIN;
pagila=*# SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;
 rekening_id |   saldo
-------------+------------
           1 | 1000000.00

## Sesi B
pagila=# BEGIN;
pagila=*# SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;
(menunggu, tidak langsung mengembalikan hasil; hasil baru keluar setelah Sesi A COMMIT)

## Pengamat (saat Sesi B masih menunggu)
pagila=# SELECT b.application_name AS menunggu, b.wait_event_type, b.wait_event,
       a.application_name AS diblokir_oleh
FROM pg_stat_activity b
JOIN pg_stat_activity a ON a.pid = ANY (pg_blocking_pids(b.pid))
WHERE b.application_name LIKE 'Sesi%';
 menunggu | wait_event_type |  wait_event   | diblokir_oleh
----------+-----------------+---------------+---------------
 Sesi B   | Lock            | transactionid | Sesi A
(1 row)

## Sesi A (aplikasi menghitung 1000000 - 10000 = 990000)
pagila=*# UPDATE lab9.rekening SET saldo = 990000 WHERE rekening_id = 1;
UPDATE 1
pagila=*# COMMIT;
COMMIT

## Sesi B (dilepas setelah Sesi A COMMIT)
 rekening_id |   saldo
-------------+-----------
           1 | 990000.00
pagila=*# UPDATE lab9.rekening SET saldo = 980000 WHERE rekening_id = 1;   -- 990000 - 10000
UPDATE 1
pagila=*# COMMIT;
COMMIT

## Hasil
pagila=# SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;
 rekening_id |   saldo
-------------+-----------
           1 | 980000.00
```

### Q14
Buat kolom versi (version_no) atau gunakan nilai saldo yang dibaca sebagai kondisi UPDATE. Tunjukkan bagaimana aplikasi mengetahui bahwa data sudah berubah.
>> Dibuat tabel bantu lab9.rekening_versi (salinan rekening + kolom version_no) agar struktur lab9.rekening tidak berubah. Sesi A dan B sama-sama membaca (saldo 1000000.00, version_no 1). Sesi A UPDATE ... WHERE version_no = 1 -> UPDATE 1 lalu COMMIT (versi menjadi 2). Sesi B UPDATE ... WHERE version_no = 1 -> UPDATE 0: tidak ada baris yang cocok, sehingga aplikasi tahu data sudah diubah pihak lain dan tidak menimpa apa pun. Sesi B ROLLBACK, membaca ulang (1100000.00, versi 2), menghitung ulang, dan UPDATE ... WHERE version_no = 2 -> UPDATE 1. Saldo akhir 1300000.00 (versi 3); kedua penambahan tercatat. Pada varian memakai nilai saldo sebagai kondisi (WHERE saldo = 1000000), Sesi B juga mendapat UPDATE 0 dan saldo tetap 1100000.00. Pada uji ABA, saldo dinaikkan lalu dikembalikan ke 1000000.00 (version_no sudah 3): kondisi version_no = 1 menghasilkan UPDATE 0 (terdeteksi), sedangkan kondisi saldo = 1000000 menghasilkan UPDATE 1 (tidak terdeteksi).
Status: konflik terdeteksi lewat jumlah baris terpengaruh (UPDATE 0); tidak ada lost update.
Ini optimistic locking: tidak mengunci saat membaca, hanya memverifikasi saat menulis bahwa data belum berubah, dan bila gagal transaksi diulang dari awal (baca ulang, hitung ulang, tulis lagi). Cocok untuk konflik yang jarang dan waktu "berpikir" pengguna yang lama, karena tidak ada lock yang ditahan. Kelemahan kondisi nilai saldo: nilai bisa kebetulan kembali sama (masalah ABA) sehingga perubahan tidak terdeteksi. version_no selalu bertambah, jadi lebih andal.

**Persiapan: tabel bantu**
```
## Sesi A
pagila=# DROP TABLE IF EXISTS lab9.rekening_versi;
pagila=# CREATE TABLE lab9.rekening_versi (
    rekening_id INT PRIMARY KEY,
    pemilik     TEXT NOT NULL,
    saldo       NUMERIC(12,2) NOT NULL CHECK (saldo >= 0),
    version_no  INT NOT NULL DEFAULT 1
);
CREATE TABLE
pagila=# INSERT INTO lab9.rekening_versi (rekening_id, pemilik, saldo)
SELECT rekening_id, pemilik, saldo FROM lab9.rekening;
INSERT 0 2
pagila=# SELECT * FROM lab9.rekening_versi ORDER BY rekening_id;
 rekening_id | pemilik |   saldo    | version_no
-------------+---------+------------+------------
           1 | Ani     | 1000000.00 |          1
           2 | Budi    | 1000000.00 |          1
```

**14a. Optimistic locking dengan version_no**
```
## Sesi A
pagila=# BEGIN;
pagila=*# SELECT rekening_id, saldo, version_no FROM lab9.rekening_versi WHERE rekening_id = 1;
 rekening_id |   saldo    | version_no
-------------+------------+------------
           1 | 1000000.00 |          1

## Sesi B
pagila=# BEGIN;
pagila=*# SELECT rekening_id, saldo, version_no FROM lab9.rekening_versi WHERE rekening_id = 1;
 rekening_id |   saldo    | version_no
-------------+------------+------------
           1 | 1000000.00 |          1

## Sesi A (+100000)
pagila=*# UPDATE lab9.rekening_versi SET saldo = 1100000, version_no = version_no + 1
WHERE rekening_id = 1 AND version_no = 1;
UPDATE 1
pagila=*# COMMIT;
COMMIT

## Sesi B (+200000, masih memegang version_no = 1)
pagila=*# UPDATE lab9.rekening_versi SET saldo = 1200000, version_no = version_no + 1
WHERE rekening_id = 1 AND version_no = 1;
UPDATE 0
pagila=*# ROLLBACK;
ROLLBACK

## Sesi B (ulang: baca ulang, hitung ulang, update)
pagila=# BEGIN;
pagila=*# SELECT rekening_id, saldo, version_no FROM lab9.rekening_versi WHERE rekening_id = 1;
 rekening_id |   saldo    | version_no
-------------+------------+------------
           1 | 1100000.00 |          2
pagila=*# UPDATE lab9.rekening_versi SET saldo = 1300000, version_no = version_no + 1
WHERE rekening_id = 1 AND version_no = 2;
UPDATE 1
pagila=*# COMMIT;
COMMIT

## Hasil (Sesi A)
pagila=# SELECT rekening_id, saldo, version_no FROM lab9.rekening_versi WHERE rekening_id = 1;
 rekening_id |   saldo    | version_no
-------------+------------+------------
           1 | 1300000.00 |          3
```

**14b. Varian: nilai saldo yang dibaca sebagai kondisi UPDATE**
```
## Sesi A
pagila=# BEGIN;
pagila=*# SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;
 rekening_id |   saldo
-------------+------------
           1 | 1000000.00

## Sesi B
pagila=# BEGIN;
pagila=*# SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;
 rekening_id |   saldo
-------------+------------
           1 | 1000000.00

## Sesi A
pagila=*# UPDATE lab9.rekening SET saldo = 1100000 WHERE rekening_id = 1 AND saldo = 1000000;
UPDATE 1
pagila=*# COMMIT;
COMMIT

## Sesi B
pagila=*# UPDATE lab9.rekening SET saldo = 1200000 WHERE rekening_id = 1 AND saldo = 1000000;
UPDATE 0
pagila=*# ROLLBACK;
ROLLBACK

## Hasil (Sesi A)
pagila=# SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;
 rekening_id |   saldo
-------------+------------
           1 | 1100000.00
```

**14c. Keterbatasan kondisi saldo (ABA): saldo dikembalikan ke nilai awal**
```
## Sesi A
pagila=# UPDATE lab9.rekening_versi SET saldo = 1000000, version_no = 1 WHERE rekening_id = 1;
UPDATE 1

## Sesi B (membaca, lalu menahan bacaan lama)
pagila=# BEGIN;
pagila=*# SELECT rekening_id, saldo, version_no FROM lab9.rekening_versi WHERE rekening_id = 1;
 rekening_id |   saldo    | version_no
-------------+------------+------------
           1 | 1000000.00 |          1

## Sesi A (saldo dinaikkan lalu dikembalikan)
pagila=# UPDATE lab9.rekening_versi SET saldo = saldo + 100000, version_no = version_no + 1 WHERE rekening_id = 1;
UPDATE 1
pagila=# UPDATE lab9.rekening_versi SET saldo = saldo - 100000, version_no = version_no + 1 WHERE rekening_id = 1;
UPDATE 1
pagila=# SELECT rekening_id, saldo, version_no FROM lab9.rekening_versi WHERE rekening_id = 1;
 rekening_id |   saldo    | version_no
-------------+------------+------------
           1 | 1000000.00 |          3

## Sesi B
pagila=*# UPDATE lab9.rekening_versi SET saldo = 1200000, version_no = version_no + 1
WHERE rekening_id = 1 AND version_no = 1;
UPDATE 0
pagila=*# UPDATE lab9.rekening_versi SET saldo = 1200000, version_no = version_no + 1
WHERE rekening_id = 1 AND saldo = 1000000;
UPDATE 1
pagila=*# ROLLBACK;
ROLLBACK

## Pembersihan
pagila=# DROP TABLE lab9.rekening_versi;
DROP TABLE
pagila=# UPDATE lab9.rekening SET saldo = 1000000 WHERE rekening_id IN (1,2);
UPDATE 2
```

### Q15
Jalankan dua SELECT biasa di tengah transaksi berbeda. Jelaskan secara konseptual bagaimana MVCC memungkinkan pembaca melihat snapshot tanpa selalu menunggu penulis.
>> Sesi A (REPEATABLE READ) membaca saldo rekening 1 = 1000000.00 dan snapshot-nya 1492:1492:. Sesi B memulai transaksi dengan xid 1492, mengubah saldo menjadi 1100000 (belum COMMIT), dan SELECT di Sesi B melihat 1100000.00. Pada saat itu SELECT di Sesi A langsung kembali (0.226 ms, tidak menunggu) dengan 1000000.00. Setelah Sesi B COMMIT, SELECT Sesi A tetap 1000000.00 dan pg_current_snapshot() tetap 1492:1492:. pg_locks Sesi A hanya menunjukkan AccessShareLock. Setelah Sesi A COMMIT, SELECT berikutnya membaca 1100000.00.
Status: pembaca tidak diblokir penulis; dua transaksi melihat nilai berbeda secara bersamaan.
PostgreSQL tidak menimpa baris saat UPDATE, melainkan membuat versi baris baru sementara versi lama tetap ada. Setiap transaksi memegang snapshot, yaitu penanda transaksi mana yang dianggap sudah selesai pada saat snapshot diambil. Snapshot 1492:1492: berarti semua transaksi dengan xid >= 1492 dianggap belum terjadi; xid Sesi B = 1492, sehingga versi baru buatannya tidak terlihat oleh Sesi A, dan versi lama dibaca. Di REPEATABLE READ snapshot ini diambil sekali pada query pertama dan dipakai sampai transaksi selesai, karena itu nilainya tetap walaupun Sesi B sudah COMMIT. Pembaca hanya memegang AccessShareLock pada tabel, yang tidak bentrok dengan lock penulis, dan tidak mengunci baris, sehingga pembaca tidak menunggu penulis dan penulis tidak menunggu pembaca. Penulis tetap menunggu penulis lain pada baris yang sama (Q12-Q13).

```
## Sesi A
pagila=# \timing on
pagila=# BEGIN ISOLATION LEVEL REPEATABLE READ;
BEGIN
pagila=*# SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;
 rekening_id |   saldo
-------------+------------
           1 | 1000000.00
Time: 0.649 ms
pagila=*# SELECT pg_current_snapshot();
 pg_current_snapshot
---------------------
 1492:1492:

## Sesi B (ubah, belum COMMIT)
pagila=# BEGIN;
pagila=*# UPDATE lab9.rekening SET saldo = saldo + 100000 WHERE rekening_id = 1;
UPDATE 1
pagila=*# SELECT pg_current_xact_id() AS xid_sesi_b;
 xid_sesi_b
------------
       1492
pagila=*# SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;
 rekening_id |   saldo
-------------+------------
           1 | 1100000.00

## Sesi A (Sesi B belum COMMIT)
pagila=*# SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;
 rekening_id |   saldo
-------------+------------
           1 | 1000000.00
Time: 0.226 ms

## Sesi B
pagila=*# COMMIT;
COMMIT

## Sesi A (Sesi B sudah COMMIT, Sesi A masih di transaksi lama)
pagila=*# SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;
 rekening_id |   saldo
-------------+------------
           1 | 1000000.00
Time: 0.296 ms
pagila=*# SELECT pg_current_snapshot();
 pg_current_snapshot
---------------------
 1492:1492:
pagila=*# SELECT mode, granted FROM pg_locks
WHERE pid = pg_backend_pid() AND locktype = 'relation' AND relation = 'lab9.rekening'::regclass;
      mode       | granted
-----------------+---------
 AccessShareLock | t

## Sesi A (setelah COMMIT)
pagila=*# COMMIT;
COMMIT
pagila=# SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;
 rekening_id |   saldo
-------------+------------
           1 | 1100000.00
pagila=# \timing off
```

### Q16
Baca nilai xmin dan xmax untuk satu baris. Jelaskan bahwa keduanya metadata transaksi PostgreSQL, bukan kolom bisnis biasa; satu nilai saja tidak cukup untuk mendiagnosis semua status visibilitas.
>> xmin/xmax tidak ada di definisi tabel (CREATE TABLE lab9.rekening hanya punya rekening_id, pemilik, saldo) tetapi dapat di-SELECT. (1) Kondisi awal rekening 1: xmin = 1494, xmax = 0, ctid = (0,34). (2) Sesi B (xid 1495) UPDATE tanpa COMMIT: versi baru yang dilihat Sesi B punya xmin = 1495, xmax = 0, ctid = (0,36) (versi fisik baru di lokasi berbeda), saldo 1000001.00. Sesi A masih melihat versi lama: xmin = 1494, xmax = 1495 (tidak nol), pg_xact_status(xmax) = in progress, dan barisnya tetap terlihat dengan saldo 1000000.00. (3) Setelah Sesi B ROLLBACK, Sesi A melihat baris yang sama: xmax tetap 1495, tetapi status berubah menjadi aborted dan baris tetap terlihat. (4) Sesi A (xid 1496) menjalankan SELECT ... FOR UPDATE pada rekening 2; Sesi B membaca rekening 2: xmin = 1494, xmax = 1496, ctid = (0,35), saldo 1000000.00, padahal baris tidak dihapus atau diubah.
Status: xmax yang tidak nol tidak berarti baris sudah dihapus atau tidak terlihat.
xmin adalah ID transaksi yang membuat versi baris itu, dan xmax adalah ID transaksi yang menghapus/memperbarui versi itu atau yang menguncinya (FOR UPDATE/SHARE). Keduanya metadata MVCC internal PostgreSQL, bukan data bisnis. Visibilitas suatu baris ditentukan dengan membandingkan xmin/xmax dengan snapshot pembaca dan status transaksi tersebut (committed, aborted, atau in progress). Karena itu satu nilai saja tidak cukup: pada eksperimen xmax = 1495 muncul dua kali dengan nilai yang sama, tetapi artinya berbeda (transaksi yang masih berjalan, lalu transaksi yang dibatalkan), dan keduanya membuat baris tetap terlihat; xmax = 1496 hanya berasal dari row lock, bukan penghapusan. Sebaliknya xmin saja tidak memberi tahu apakah transaksi pembuatnya sudah commit atau apakah snapshot pembaca boleh melihatnya. Diagnosis perlu angka xmin/xmax bersama status transaksinya (pg_xact_status) dan snapshot pembaca. Perhatikan juga bahwa xid hanya bermakna di dalam siklus transaksi PostgreSQL; ia bukan atribut bisnis dan nilainya berubah setiap ada pembaruan.

```
## Sesi A (kondisi awal)
pagila=# UPDATE lab9.rekening SET saldo = 1000000 WHERE rekening_id IN (1,2);
UPDATE 2
pagila=# SELECT xmin, xmax, ctid, rekening_id, saldo FROM lab9.rekening ORDER BY rekening_id;
 xmin | xmax |  ctid  | rekening_id |   saldo
------+------+--------+-------------+------------
 1494 |    0 | (0,34) |           1 | 1000000.00
 1494 |    0 | (0,35) |           2 | 1000000.00

## Sesi B (update tanpa COMMIT)
pagila=# BEGIN;
pagila=*# UPDATE lab9.rekening SET saldo = saldo + 1 WHERE rekening_id = 1;
UPDATE 1
pagila=*# SELECT pg_current_xact_id() AS xid_sesi_b;
 xid_sesi_b
------------
       1495
pagila=*# SELECT xmin, xmax, ctid, saldo FROM lab9.rekening WHERE rekening_id = 1;
 xmin | xmax |  ctid  |   saldo
------+------+--------+------------
 1495 |    0 | (0,36) | 1000001.00

## Sesi A (Sesi B belum COMMIT)
pagila=# SELECT xmin, xmax, ctid, saldo, pg_xact_status(xmax::text::xid8) AS status_xmax
FROM lab9.rekening WHERE rekening_id = 1;
 xmin | xmax |  ctid  |   saldo    | status_xmax
------+------+--------+------------+-------------
 1494 | 1495 | (0,34) | 1000000.00 | in progress

## Sesi B
pagila=*# ROLLBACK;
ROLLBACK

## Sesi A (setelah Sesi B ROLLBACK)
pagila=# SELECT xmin, xmax, ctid, saldo, pg_xact_status(xmax::text::xid8) AS status_xmax
FROM lab9.rekening WHERE rekening_id = 1;
 xmin | xmax |  ctid  |   saldo    | status_xmax
------+------+--------+------------+-------------
 1494 | 1495 | (0,34) | 1000000.00 | aborted

## Sesi A (row lock memengaruhi xmax)
pagila=# BEGIN;
pagila=*# SELECT pg_current_xact_id() AS xid_sesi_a;
 xid_sesi_a
------------
       1496
pagila=*# SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 2 FOR UPDATE;
 rekening_id |   saldo
-------------+------------
           2 | 1000000.00

## Sesi B
pagila=# SELECT xmin, xmax, ctid, saldo FROM lab9.rekening WHERE rekening_id = 2;
 xmin | xmax |  ctid  |   saldo
------+------+--------+------------
 1494 | 1496 | (0,35) | 1000000.00

## Sesi A
pagila=*# ROLLBACK;
ROLLBACK
```

### Q17
Jelaskan manfaat MVCC dan mengapa vacuum diperlukan untuk mengelola versi baris yang sudah tidak diperlukan.
>> Dibuat tabel lab9.mvcc_demo (autovacuum dimatikan hanya untuk tabel ini agar hasil VACUUM dapat diamati), diisi satu baris lalu di-UPDATE 5 kali; SELECT hanya menampilkan 1 baris (nilai = 5), tetapi setiap UPDATE meninggalkan versi baris lama di tabel. Sesi B (REPEATABLE READ) membuka transaksi dan membaca nilai 5, lalu Sesi A UPDATE sekali lagi dan menjalankan VACUUM (VERBOSE). Hasilnya: "tuples: 5 removed, 2 remain, 1 are dead but not yet removable". Lima versi lama dibuang, tetapi satu versi mati (nilai 5) tidak boleh dibuang karena masih dibutuhkan snapshot Sesi B. Setelah Sesi B COMMIT, VACUUM berikutnya melaporkan "tuples: 1 removed, 1 remain, 0 are dead but not yet removable": versi tadi akhirnya terbuang dan hanya versi terbaru yang tersisa.
Status: versi baris lama menumpuk dan baru bisa dibersihkan setelah tidak ada snapshot yang memerlukannya.
Manfaat MVCC: pembaca tidak memblokir penulis dan sebaliknya (Q15), setiap transaksi mendapat tampilan data yang konsisten sesuai snapshot-nya, dan pembatalan transaksi murah karena versi lama masih ada. Harganya: UPDATE dan DELETE tidak menimpa baris, melainkan menyisakan versi lama (dead tuple) yang memakan ruang dan memperlambat pemindaian tabel (bloat). VACUUM (dan autovacuum) membuang versi yang sudah tidak terlihat oleh snapshot mana pun sehingga ruangnya dapat dipakai ulang, memperbarui peta visibilitas dan free space, serta membekukan xid lama agar tidak terjadi transaction ID wraparound. Eksperimen menunjukkan batasnya: transaksi yang lama terbuka menahan pembersihan ("dead but not yet removable"), sehingga transaksi harus dibuat singkat.

```
## Sesi A (persiapan; autovacuum dimatikan hanya untuk tabel demo)
pagila=# CREATE TABLE lab9.mvcc_demo (id INT PRIMARY KEY, nilai INT) WITH (autovacuum_enabled = false);
CREATE TABLE
pagila=# INSERT INTO lab9.mvcc_demo VALUES (1, 0);
INSERT 0 1
pagila=# UPDATE lab9.mvcc_demo SET nilai = nilai + 1 WHERE id = 1;   -- dijalankan 5 kali
UPDATE 1
pagila=# SELECT * FROM lab9.mvcc_demo;
 id | nilai
----+-------
  1 |     5

## Sesi B (transaksi lama yang menahan snapshot)
pagila=# BEGIN ISOLATION LEVEL REPEATABLE READ;
BEGIN
pagila=*# SELECT * FROM lab9.mvcc_demo;
 id | nilai
----+-------
  1 |     5

## Sesi A (Sesi B masih terbuka)
pagila=# UPDATE lab9.mvcc_demo SET nilai = nilai + 1 WHERE id = 1;
UPDATE 1
pagila=# VACUUM (VERBOSE) lab9.mvcc_demo;
INFO:  vacuuming "pagila.lab9.mvcc_demo"
INFO:  finished vacuuming "pagila.lab9.mvcc_demo": index scans: 0
pages: 0 removed, 1 remain, 1 scanned (100.00% of total)
tuples: 5 removed, 2 remain, 1 are dead but not yet removable
(baris lain dari output VERBOSE dipangkas)
VACUUM

## Sesi B
pagila=*# COMMIT;
COMMIT

## Sesi A (setelah Sesi B COMMIT)
pagila=# VACUUM (VERBOSE) lab9.mvcc_demo;
INFO:  vacuuming "pagila.lab9.mvcc_demo"
INFO:  finished vacuuming "pagila.lab9.mvcc_demo": index scans: 0
pages: 0 removed, 1 remain, 1 scanned (100.00% of total)
tuples: 1 removed, 1 remain, 0 are dead but not yet removable
(baris lain dari output VERBOSE dipangkas)
VACUUM

## Pembersihan
pagila=# DROP TABLE lab9.mvcc_demo;
DROP TABLE
```