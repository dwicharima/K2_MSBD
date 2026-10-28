# Laporan Latihan Kelompok Pertemuan 9

| Nama                   | NIM       | Kontribusi |
|------------------------|-----------|------------|
| Agnes Natalia Siregar  | 251402108 | Langkah 1: Setup lingkungan pengujian, pengerjaan Q00 dan Q1–Q5 |
| Rasyd Arija A. Ritonga  | 251402020 | Langkah 2: Pengerjaan pengujian Q6–Q11 |
| Abdullah Zufar Aulia   | 251402111 | Langkah 3: Pengerjaan pengujian Q12–Q19 |
| Fakhry Adrian Daulay   | 251402053 | Langkah 4: Pengerjaan pengujian Q20–Q23 |
| Dwi Charima Husni      | 251402088 | Langkah 5–6: Pengerjaan pengujian Q24–Q29 |

Versi PostgreSQL: 17.11  
Alat: Docker, PowerShell, dan psql  
Container: msbd-pg  
Database: latihan  
Schema: lab9

## Jawaban Q1–Q32
### Q1
Buktikan kondisi awal dan jumlah saldo keseluruhan.
>> Data awal memuat saldo masing-masing sebesar Rp1.000.000 untuk Ani dan Budi sehingga total keseluruhan saldo di awal adalah Rp2.000.000.
```
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
```

---

### Q2
Jalankan BEGIN, ubah saldo, lalu periksa hasil sebelum COMMIT. Apa yang terlihat di sesi lain?
>> Di Sesi A: Saldo Ani berubah menjadi 800000.00, Budi tetap 1000000.00.
Di Sesi B: Saldo Ani masih tetap 1000000.00 dan Budi 1000000.00 (belum berubah).
Status: Transaksi aktif di Sesi A (belum COMMIT / ROLLBACK).
Terjadi karena penerapan aturan Isolation (khususnya tingkat Read Committed default PostgreSQL). Perubahan data yang dilakukan dalam satu transaksi aktif (BEGIN) di Sesi A tidak akan terlihat oleh sesi lain (Sesi B) sebelum transaksi tersebut di-commit secara permanen. Hal ini mencegah dirty read.

```
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
```

---

### Q3
Bandingkan COMMIT dan ROLLBACK. Perubahan mana yang bertahan?
>> Setelah COMMIT, perubahan saldo Budi permanen tersimpan di database dan bisa dilihat oleh sesi lain.
Setelah ROLLBACK, saldo Budi kembali seperti semula sebelum blok BEGIN dijalankan.
Status: COMMIT (Permanen), ROLLBACK (Dibatalkan).
Perintah COMMIT mengakhiri transaksi dan menyimpan semua perubahan secara permanen ke dalam basis data. Sebaliknya, perintah ROLLBACK membatalkan seluruh perubahan yang dilakukan selama transaksi berlangsung dan mengembalikan kondisi data ke keadaan semula sebelum transaksi dimulai.

```
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
```

---

### Q4
Buat transaksi dengan SAVEPOINT, ubah saldo, lalu jalankan ROLLBACK TO SAVEPOINT. Bagian mana yang dibatalkan?
>> Hasil SELECT: Saldo Ani hanya bertambah 50.000 dari Perubahan 1, sementara penambahan 500.000 dari Perubahan 2 dibatalkan.
Status: Berhasil di-rollback sebagian ke sp_satu.
Perintah ROLLBACK TO SAVEPOINT hanya membatalkan pernyataan SQL yang dieksekusi setelah titik penanda (SAVEPOINT) tersebut dibuat. Perubahan yang terjadi sebelum SAVEPOINT tetap aman dan dipertahankan di dalam transaksi.

```
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
```

---

### Q5
Jelaskan bagaimana atomicity dan consistency didukung oleh transaksi dan constraint CHECK.
>> Atomicity (Atomisitas): Didukung penuh oleh mekanisme transaksi (BEGIN, COMMIT, ROLLBACK). Prinsip ini memastikan bahwa seluruh rangkaian perintah di dalam blok transaksi diperlakukan sebagai satu kesatuan utuh (all-or-nothing). Jika ada satu saja perintah yang gagal di tengah jalan, seluruh perubahan akan dibatalkan (rollback) sehingga tidak ada data setengah jadi yang tersimpan.
Consistency (Konsistensi): Didukung oleh kombinasi transaksi dan aturan constraint (seperti PRIMARY KEY dan CHECK (saldo >= 0) yang kita buat di awal). Constraint berfungsi sebagai penjaga aturan integritas data agar database selalu berada dalam kondisi valid. Jika ada transaksi yang mencoba melanggar aturan (misalnya memaksa saldo menjadi negatif), transaksi tersebut akan ditolak oleh sistem dan dibatalkan, sehingga konsistensi data tetap terjaga.

### Q6 — Non-repeatable read
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

### Q7 — Perbandingan isolation
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

### Q8 — Phantom read
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

### Q9 — Dirty read
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

### Q10 — Lost update
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
>> [Q11_table_ringkasan.md](Q11_table_ringkasan.md)

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
>> Dibuat tabel bantu lab9.rekening_versi (salinan rekening + kolom version_no) agar struktur lab9.rekening tidak berubah. Sesi A dan B sama-sama membaca (saldo 1000000.00, version_no 1). Sesi A UPDATE ... WHERE version_no = 1 -> UPDATE 1 lalu COMMIT (versi menjadi 2). Sesi B UPDATE ... WHERE version_no = 1 -> UPDATE 0: tidak ada baris yang cocok, sehingga aplikasi tahu data sudah diubah pihak lain dan tidak menimpa apa pun. Sesi B ROLLBACK, membaca ulang (1100000.00, versi 2), menghitung ulang, dan UPDATE ... WHERE version_no = 2 -> UPDATE 1. Saldo akhir 1300000.00 (versi 3); kedua penambahan tercatat. Pada varian memakai nilai saldo sebagai kondisi (WHERE saldo = 1000000), Sesi B juga mendapat UPDATE 0 dan saldo tetap 1100000.00. Pada uji ABA, saldo dinaikkan lalu dikembalikan ke 1000000.00 (version_no sudah 3): kondisi version_no = 1 menghasilkan UPDATE 0 (terdeteksi), sedangkan kondisi saldo = 1000000 menghasilkan UPDATE 1 (tidak terdeteksi). Status: konflik terdeteksi lewat jumlah baris terpengaruh (UPDATE 0); tidak ada lost update. Ini optimistic locking: tidak mengunci saat membaca, hanya memverifikasi saat menulis bahwa data belum berubah, dan bila gagal transaksi diulang dari awal (baca ulang, hitung ulang, tulis lagi). Cocok untuk konflik yang jarang dan waktu "berpikir" pengguna yang lama, karena tidak ada lock yang ditahan. Kelemahan kondisi nilai saldo: nilai bisa kebetulan kembali sama (masalah ABA) sehingga perubahan tidak terdeteksi. version_no selalu bertambah, jadi lebih andal.

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

### Q18
Bandingkan FOR UPDATE, FOR NO KEY UPDATE, FOR SHARE, dan FOR KEY SHARE. Jelaskan tujuan umum dan kapan transaksi lain mungkin terhalang.
>> Keempat jenis lock memiliki tingkat perlindungan dan kompatibilitas berbeda. Transaksi lain dapat menunggu apabila lock yang dimintanya bertentangan dengan lock yang sudah dipegang transaksi pertama. FOR UPDATE mengunci baris secara kuat untuk melindungi pembaruan, termasuk perubahan kolom yang menjadi key. FOR NO KEY UPDATE digunakan ketika baris akan diperbarui, tetapi perubahan tersebut tidak mengubah key yang relevan bagi foreign key. FOR SHARE mengizinkan transaksi lain membaca dan mengambil lock bersama, tetapi dapat menghalangi transaksi yang ingin mengubah baris. FOR KEY SHARE lock yang lebih ringan, terutama untuk melindungi key baris agar tidak dihapus atau diubah dengan cara yang bertentangan.

---

### Q19
Di Sesi A, mulai transaksi dan kunci rekening 1 dengan SELECT ... FOR UPDATE. Di Sesi B, coba mengunci baris yang sama. Catat perilaku menunggu dan apa yang terjadi setelah Sesi A COMMIT.
>> Sesi B tertahan sampai Sesi A melakukan COMMIT. Ini adalah rowlock, bukan deadlock.
```

### Q20 — Deadlock. 
Sesi A mulai transaksi dan mengunci rekening 1; Sesi B mulai transaksi dan mengunci rekening 2. Selanjutnya Sesi A mencoba mengunci rekening 2, lalu Sesi B mencoba mengunci rekening 1. Rekam sesi mana yang mendapat deadlock error dan SQLSTATE 40P01.
>> Sesi yang terkena deadlock adalah Sesi B. Pada Sesi B yang terkena deadlock, akan memunculkan pesan 
ERROR:  deadlock detected
DETAIL:  Process 1961 waits for ShareLock on transaction 1230; blocked by process 834.
Process 834 waits for ShareLock on transaction 1231; blocked by process 1961.
HINT:  See server log for query details.
CONTEXT:  while locking tuple (0,1) in relation "rekening"
```

### Q21
Ulangi dengan urutan penguncian konsisten: semua sesi mengunci rekening_id dari nilai terkecil ke terbesar. Apakah deadlock dapat dihindari pada skenario ini?
>> Pada skenario ini, urutan lock yang konsisten dapat menghindari deadlock karena kedua transaksi tidak saling memegang lock dalam urutan yang berlawanan.

---

### Q22
Jelaskan perbedaan deadlock dan antrean lock panjang. Gunakan contoh transaksi yang menahan lock terlalu lama.
>> Deadlock: dua atau lebih transaksi membentuk siklus saling menunggu. PostgreSQL akan mendeteksinya dan membatalkan salah satu transaksi.
Antrean lock panjang: transaksi menunggu lock yang dipegang transaksi lain, tetapi tidak terbentuk siklus deadlock.
Contoh antrean lock panjang:

Dijalankan di Sesi A
BEGIN;

SELECT *
FROM lab9.rekening
WHERE rekening_id = 1
FOR UPDATE;

-- Biarkan transaksi tetap terbuka.

Lalu, dijalankan pada Sesi B
BEGIN;

SELECT *
FROM lab9.rekening
WHERE rekening_id = 1
FOR UPDATE;

Sesi B menunggu sampai Sesi A menyelesaikan transaksi. Jika Sesi A terlalu lama dibiarkan terbuka, antrean tersebut juga bisa berlangsung lama.

Akhiri transaksi Sesi A dengan COMMIT;, kemudian selesaikan Sesi B dengan COMMIT; juga.

Deadlock membutuhkan siklus saling menunggu, sedangkan antrean lock panjang cukup terjadi karena satu transaksi menahan lock terlalu lama.

---

### Q23
Bandingkan lock_timeout, statement_timeout, idle_in_transaction_session_timeout, dan deadlock_timeout. Jelaskan fungsi masing-masing.
>> lock_timeout : Membatasi berapa lama perintah menunggu untuk mendapatkan lock.
statement_timeout : Membatasi durasi keseluruhan eksekusi sebuah perintah SQL.
idle_in_transaction_session_timeout : Mengakhiri sesi yang terlalu lama tidak aktif ketika masih berada dalam transaksi terbuka.
deadlock_timeout : Menentukan berapa lama PostgreSQL menunggu sebelum melakukan pemeriksaan deadlock pada situasi lock yang menunggu.

Keempat parameter memiliki fungsi berbeda. lock_timeout membatasi waktu tunggu lock, statement_timeout membatasi waktu eksekusi query, idle_in_transaction_session_timeout mengatasi transaksi yang dibiarkan diam, sedangkan deadlock_timeout mengatur kapan PostgreSQL mulai memeriksa deadlock.

---

### Q24 — SKIP LOCKED
Buat tabel antrean pekerjaan dengan id dan status. Kunci satu baris pada Sesi A. Pada Sesi B, jalankan SELECT ... FOR UPDATE SKIP LOCKED. Baris mana yang dikembalikan? Jelaskan kegunaannya untuk worker antrean.
>> Perintah FOR UPDATE SKIP LOCKED digunakan untuk mengambil baris yang tidak sedang dikunci oleh transaksi lain tanpa harus menunggu. Pada pengujian ini, Sesi A mengunci pekerjaan dengan id = 1, sehingga Sesi B melewati baris tersebut dan mendapatkan pekerjaan dengan id = 2 dan id = 3.

Fitur ini berguna pada sistem antrean pekerjaan yang memiliki beberapa worker, agar setiap worker dapat mengambil pekerjaan yang tersedia tanpa menunggu pekerjaan yang sedang diproses oleh worker lain.

#### Hasil Percobaan

**1. Persiapan tabel antrean pekerjaan**

Tabel lab9.antrean_pekerjaan berisi tiga pekerjaan dengan status menunggu.

```
CREATE TABLE IF NOT EXISTS lab9.antrean_pekerjaan (
    id INT PRIMARY KEY,
    status TEXT NOT NULL
);

INSERT INTO lab9.antrean_pekerjaan (id, status)
VALUES
    (1, 'menunggu'),
    (2, 'menunggu'),
    (3, 'menunggu')
ON CONFLICT (id) DO NOTHING;

SELECT * FROM lab9.antrean_pekerjaan
ORDER BY id;
```

Hasil:

```
 id |  status
----+----------
  1 | menunggu
  2 | menunggu
  3 | menunggu
(3 rows)
```

**2. Sesi A — Mengunci pekerjaan dengan id = 1**

```
BEGIN;

SELECT *
FROM lab9.antrean_pekerjaan
WHERE id = 1
FOR UPDATE;
```

Hasil:

```
BEGIN
 id |  status
----+----------
  1 | menunggu
(1 row)
```

Transaksi Sesi A dibiarkan terbuka agar baris dengan id = 1 tetap terkunci saat Sesi B menjalankan query.

**3. Sesi B — Mengambil pekerjaan yang tidak terkunci**

```
BEGIN;

SELECT *
FROM lab9.antrean_pekerjaan
WHERE status = 'menunggu'
ORDER BY id
FOR UPDATE SKIP LOCKED;
```

Hasil:

```
BEGIN
 id |  status
----+----------
  2 | menunggu
  3 | menunggu
(2 rows)
```

Sesi B mendapatkan pekerjaan dengan id = 2 dan id = 3, sedangkan pekerjaan dengan id = 1 dilewati karena sedang dikunci Sesi A.

**4. Mengakhiri transaksi**

Setelah hasil pengujian diperoleh, transaksi diakhiri dengan menjalankan COMMIT pada kedua sesi. Kedua transaksi berhasil diselesaikan.

### Penjelasan dan Kesimpulan

Berdasarkan hasil percobaan, FOR UPDATE SKIP LOCKED berhasil melewati baris dengan id = 1 yang sedang dikunci Sesi A dan mengembalikan dua baris lainnya, yaitu id = 2 dan id = 3. Hal ini menunjukkan bahwa PostgreSQL dapat mengambil baris yang tersedia tanpa menunggu kunci pada baris lain dilepaskan.

Fitur ini bermanfaat untuk sistem antrean pekerjaan dengan banyak worker, karena setiap worker dapat mengambil pekerjaan yang belum dikunci oleh transaksi lain sehingga pemrosesan antrean dapat berjalan lebih efisien.

---

### Q25 — NOWAIT
Ulangi penguncian baris yang sama menggunakan FOR UPDATE NOWAIT. Catat bahwa perintah gagal segera jika baris tidak dapat dikunci, alih-alih menunggu.
>> FOR UPDATE NOWAIT digunakan untuk mengunci baris tanpa menunggu apabila baris tersebut sedang dikunci oleh transaksi lain. Jika baris tidak dapat dikunci, PostgreSQL langsung menghasilkan error. Dengan demikian, aplikasi dapat mengetahui bahwa baris sedang tidak tersedia tanpa harus menunggu kunci dilepaskan.

#### Hasil Percobaan

**1. Sesi A — Mengunci pekerjaan dengan id = 1**
```
BEGIN;

SELECT *
FROM lab9.antrean_pekerjaan
WHERE id = 1
FOR UPDATE;
```

Hasil:

```
BEGIN
 id |  status
----+----------
  1 | menunggu
(1 row)
```

Sesi A berhasil memperoleh kunci pada baris dengan id = 1. Transaksi Sesi A harus tetap terbuka ketika Sesi B menjalankan query agar konflik penguncian dapat diuji.

**2. Sesi B — Mencoba mengunci baris menggunakan NOWAIT**

```
BEGIN;

SELECT *
FROM lab9.antrean_pekerjaan
WHERE id = 1
FOR UPDATE NOWAIT;
```

Hasil:

```
BEGIN
ERROR:  could not obtain lock on row in relation "antrean_pekerjaan"
```

Perintah gagal karena baris dengan id = 1 sedang dikunci oleh transaksi lain. PostgreSQL langsung menghasilkan error tanpa menunggu kunci dilepaskan.

**3. Mengakhiri transaksi Sesi B**

Setelah terjadi error, Sesi B menjalankan ROLLBACK; dan akan menghasilkan tulisan ROLLBACK.
Perintah ROLLBACK membatalkan transaksi Sesi B yang gagal akibat error.

**4. Mengakhiri transaksi Sesi A**

Setelah pengujian selesai, Sesi A menjalankan COMMIT; dan menghasilkan tulisan COMMIT.
Transaksi Sesi A berhasil diselesaikan dan kunci baris dilepaskan.

**Penjelasan:**
Berdasarkan hasil percobaan, FOR UPDATE NOWAIT langsung menghasilkan error could not obtain lock on row in relation "antrean_pekerjaan" ketika baris dengan id = 1 sedang dikunci oleh Sesi A. Hal ini menunjukkan bahwa PostgreSQL tidak menunggu kunci dilepaskan, berbeda dengan FOR UPDATE biasa yang dapat menunggu jika terjadi konflik penguncian. Pengujian membuktikan bahwa NOWAIT dapat digunakan ketika aplikasi ingin segera mengetahui bahwa suatu baris tidak dapat dikunci. Setelah error, transaksi Sesi B dibatalkan menggunakan ROLLBACK, sedangkan Sesi A menyelesaikan transaksinya dengan COMMIT.

---

### Q26 — Write Skew
Buat tabel dokter_jaga dengan dua dokter aktif dan aturan bisnis minimal satu dokter harus tetap aktif. Jalankan dua transaksi dengan isolation level REPEATABLE READ. Masing-masing transaksi membaca jumlah dokter aktif, lalu menonaktifkan dokter yang berbeda. Amati apakah kedua transaksi dapat melakukan COMMIT dan apakah aturan bisnis dilanggar.
>> Pada isolation level REPEATABLE READ, kedua transaksi dapat berhasil melakukan COMMIT karena masing-masing mengubah baris dokter yang berbeda. Akibatnya, kedua dokter menjadi tidak aktif sehingga aturan bisnis minimal satu dokter harus tetap aktif dilanggar.

#### Hasil Pengujian

**1. Kondisi awal**
```
Tabel lab9.dokter_jaga diisi dengan dua dokter:

dokter_id | nama | aktif 
-----------+------+-------
         1 | Ani  | t
         2 | Budi | t
(2 rows)
```

**2. Sesi A**

Menjalankan transaksi dengan isolation level REPEATABLE READ dan memeriksa jumlah dokter aktif.

```BEGIN ISOLATION LEVEL REPEATABLE READ;

SELECT COUNT(*) AS dokter_aktif
FROM lab9.dokter_jaga
WHERE aktif = TRUE;
```

Hasil: dokter_aktif = 2.

Selanjutnya, Sesi A menonaktifkan Ani dan melakukan COMMIT.

```UPDATE lab9.dokter_jaga
SET aktif = FALSE
WHERE dokter_id = 1;

COMMIT;
```

Hasil: UPDATE 1 dan COMMIT berhasil.

**3. Sesi B**

Sebelum Sesi A melakukan perubahan, Sesi B juga telah memulai transaksi REPEATABLE READ dan membaca jumlah dokter aktif.

```BEGIN ISOLATION LEVEL REPEATABLE READ;

SELECT COUNT(*) AS dokter_aktif
FROM lab9.dokter_jaga
WHERE aktif = TRUE;
```

Hasil: dokter_aktif = 2.

Setelah Sesi A berhasil melakukan COMMIT, Sesi B menonaktifkan Budi dan melakukan COMMIT.

```UPDATE lab9.dokter_jaga
SET aktif = FALSE
WHERE dokter_id = 2;

COMMIT;
```

Hasil: UPDATE 1 dan COMMIT berhasil.

**4. Pemeriksaan hasil akhir**

```SELECT * FROM lab9.dokter_jaga
ORDER BY dokter_id;
```

Hasil pengujian:
```
dokter_id | nama | aktif 
-----------+------+-------
         1 | Ani  | f
         2 | Budi | f
(2 rows)
```

**Penjelasan:**
Kedua transaksi membaca jumlah dokter aktif sebanyak dua orang sebelum perubahan dilakukan. Sesi A menonaktifkan Ani, sedangkan Sesi B menonaktifkan Budi. Karena keduanya mengubah baris yang berbeda, kedua transaksi berhasil melakukan COMMIT. Fenomena ini disebut write skew, yaitu kondisi ketika dua transaksi yang berjalan bersamaan menghasilkan keadaan yang melanggar aturan bisnis meskipun masing-masing transaksi berhasil.

Pengujian membuktikan bahwa pada isolation level REPEATABLE READ, kedua transaksi dapat berhasil melakukan COMMIT, tetapi aturan bisnis minimal satu dokter harus tetap aktif dilanggar karena seluruh dokter menjadi tidak aktif.

---

### Q27 — SERIALIZABLE Mencegah Write Skew
Ulangi pengujian Q26 dengan isolation level SERIALIZABLE. Amati apakah kedua transaksi dapat melakukan COMMIT dan apakah aturan bisnis minimal satu dokter harus tetap aktif dapat dipertahankan.
>> Isolation level SERIALIZABLE mencegah write skew dengan mendeteksi konflik antartransaksi. Salah satu transaksi dapat dibatalkan jika hasilnya tidak dapat diserialisasikan, sehingga aturan bisnis tetap terpenuhi.

**Hasil Pengujian:**

**1. Kondisi awal**

Tabel lab9.dokter_jaga berisi dua dokter aktif:
```
 dokter_id | nama | aktif 
-----------+------+-------
         1 | Ani  | t
         2 | Budi | t
(2 rows)
```

**2. Sesi A**

Sesi A memulai transaksi dengan isolation level SERIALIZABLE dan membaca jumlah dokter aktif.

```BEGIN ISOLATION LEVEL SERIALIZABLE;

SELECT COUNT(*) AS dokter_aktif
FROM lab9.dokter_jaga
WHERE aktif = TRUE;
```

Hasil: dokter_aktif = 2.

Sesi A kemudian menonaktifkan Ani dan melakukan COMMIT.

```UPDATE lab9.dokter_jaga
SET aktif = FALSE
WHERE dokter_id = 1;

COMMIT;
```

Hasil: UPDATE 1 dan COMMIT berhasil.

**3. Sesi B**

Sesi B juga memulai transaksi dengan isolation level SERIALIZABLE dan membaca jumlah dokter aktif sebelum Sesi A melakukan COMMIT.
```
BEGIN ISOLATION LEVEL SERIALIZABLE;

SELECT COUNT(*) AS dokter_aktif
FROM lab9.dokter_jaga
WHERE aktif = TRUE;
```

Hasil: dokter_aktif = 2.

Sesi B kemudian menonaktifkan Budi.

```UPDATE lab9.dokter_jaga
SET aktif = FALSE
WHERE dokter_id = 2;

COMMIT;
```

Hasil: Perintah UPDATE berhasil, tetapi COMMIT gagal dengan pesan:

```ERROR: could not serialize access due to read/write dependencies among transactions
```

PostgreSQL membatalkan transaksi Sesi B karena konflik serialisasi.

**4. Pemeriksaan hasil akhir**
```
SELECT * FROM lab9.dokter_jaga
ORDER BY dokter_id;
```

**Hasil pengujian:**
```
dokter_id | nama | aktif 
-----------+------+-------
         1 | Ani  | f
         2 | Budi | t
(2 rows)
```

**Penjelasan:**

Berbeda dengan REPEATABLE READ pada Q26, isolation level SERIALIZABLE mendeteksi ketergantungan baca-tulis yang menimbulkan konflik. Oleh karena itu, Sesi A berhasil melakukan COMMIT, sedangkan Sesi B gagal saat COMMIT dan harus mengulang transaksi jika ingin mencoba kembali.

Pengujian menunjukkan bahwa SERIALIZABLE mencegah terjadinya write skew pada kasus ini. Hanya satu dokter yang berhasil dinonaktifkan, sehingga aturan bisnis minimal satu dokter harus tetap aktif tetap terpenuhi.

---

### Q28 — SIReadLock
Apa fungsi SIReadLock pada isolation level SERIALIZABLE? Apakah lock tersebut memblokir transaksi lain seperti FOR UPDATE?
>> SIReadLock digunakan PostgreSQL untuk mendeteksi ketergantungan baca-tulis antartransaksi yang dapat menyebabkan hasil transaksi tidak konsisten. Lock ini tidak memblokir transaksi lain secara langsung seperti FOR UPDATE.

**Analisis:**
1. Pada isolation level SERIALIZABLE, PostgreSQL menggunakan predicate lock yang ditampilkan sebagai SIReadLock untuk melacak data yang dibaca oleh suatu transaksi.
2. Jika transaksi lain mengubah data yang berkaitan dengan data yang dibaca tersebut, PostgreSQL dapat mendeteksi adanya konflik serialisasi.
3. Berbeda dengan FOR UPDATE, SIReadLock tidak membuat transaksi lain harus menunggu untuk mengakses atau mengubah baris yang sama.
4. Jika ketergantungan antartransaksi menyebabkan hasil yang tidak dapat diserialisasikan, PostgreSQL dapat membatalkan salah satu transaksi dengan error serialisasi.
Penjelasan:

SIReadLock bukan lock yang bertujuan menghalangi akses transaksi lain, melainkan membantu PostgreSQL mendeteksi konflik baca-tulis. Sementara itu, FOR UPDATE digunakan untuk mengunci baris agar transaksi lain yang ingin memperoleh lock yang bertentangan harus menunggu atau gagal, bergantung pada perintah yang digunakan.

Jadi, SIReadLock berfungsi mendeteksi konflik serialisasi pada isolation level SERIALIZABLE, bukan memblokir transaksi secara langsung. Mekanisme ini membantu PostgreSQL menjaga konsistensi transaksi dengan membatalkan transaksi yang berkonflik jika diperlukan.

---

**Q29 — Retry Transaksi yang Gagal**
Tulis pseudocode retry yang mengulang seluruh transaksi setelah SQLSTATE 40001 atau 40P01, membatasi percobaan, dan menggunakan jeda yang bertambah dengan jitter. Jelaskan mengapa operasi eksternal seperti mengirim surel sebaiknya dilakukan setelah COMMIT berhasil.
>> Retry adalah mekanisme untuk mengulangi transaksi yang gagal karena konflik serialisasi atau deadlock. Pengulangan harus dilakukan dari awal agar transaksi membaca data terbaru dan menghitung ulang perubahan yang akan dilakukan.

**Pseudocode:**
```
maks_percobaan = 5

UNTUK percobaan dari 1 sampai maks_percobaan:
    COBA:
        BEGIN

        BACA data terbaru
        HITUNG ulang perubahan
        JALANKAN seluruh query transaksi

        COMMIT
        KELUAR dari perulangan

    JIKA SQLSTATE = 40001 atau 40P01:
        ROLLBACK jika transaksi masih aktif

        JIKA percobaan = maks_percobaan:
            TAMPILKAN pesan gagal
            KELUAR dari perulangan

        jeda_dasar = 100 ms * 2^(percobaan - 1)
        jitter = angka acak antara 0 dan 100 ms

        TUNGGU jeda_dasar + jitter

    JIKA error lainnya:
        TANGANI error dan hentikan retry
```

**Penjelasan:**
1. Batas percobaan: Retry dibatasi maksimal lima kali agar aplikasi tidak terus mengulang transaksi tanpa batas.
2. SQLSTATE 40001: Menandakan kegagalan serialisasi.
3. SQLSTATE 40P01: Menandakan terjadinya deadlock.
4. Jeda bertambah dengan jitter: Waktu tunggu meningkat pada setiap percobaan dan ditambah jeda acak agar beberapa transaksi tidak terus mencoba kembali pada waktu yang sama.
5. Mengulang seluruh transaksi: Setelah gagal, transaksi harus dimulai kembali dari BEGIN, membaca data terbaru, dan menjalankan ulang seluruh operasi database, bukan hanya query terakhir yang gagal.

Mengapa operasi eksternal dilakukan setelah COMMIT?
>> Operasi eksternal, seperti mengirim surel atau mengirim notifikasi, sebaiknya dilakukan setelah COMMIT berhasil. Jika dilakukan sebelum COMMIT, transaksi bisa gagal setelah surel terkirim sehingga penerima mendapat notifikasi tentang perubahan yang sebenarnya tidak tersimpan di database.

Menempatkan operasi eksternal setelah COMMIT membantu menghindari kondisi tersebut. Namun, jika pengiriman harus dijamin tetap terlaksana meskipun aplikasi mengalami gangguan, pola transactional outbox dapat digunakan.

**Kesimpulannya** adalah Mekanisme retry perlu membatasi jumlah percobaan, mengulang seluruh transaksi untuk SQLSTATE 40001 atau 40P01, serta menggunakan jeda bertambah dengan jitter. Operasi eksternal sebaiknya dilakukan setelah transaksi berhasil di-commit agar tidak menimbulkan efek samping dari transaksi yang gagal.

---

### Q30 — Matriks Enam Anomali Transaksi
Susun matriks enam anomali, yaitu dirty read, non-repeatable read, phantom read, lost update, write skew, dan pembacaan yang tidak konsisten. Untuk setiap anomali, tuliskan cara reproduksi, hasil, dan mitigasinya.
>>
**Jawab:**
| Anomali | Cara reproduksi | Hasil | Mitigasi |
|---|---|---|---|
| **Dirty read** | Sesi A mengubah data tanpa COMMIT, lalu Sesi B membaca data tersebut. | Perubahan yang belum di-commit tidak terlihat. | Gunakan mekanisme isolasi transaksi PostgreSQL. |
| **Non-repeatable read** | Sesi A membaca baris. Sesi B mengubah dan melakukan COMMIT. Sesi A membaca ulang. | Pembacaan kedua dapat menghasilkan nilai berbeda. | Gunakan REPEATABLE READ. |
| **Phantom read** | Sesi A membaca data berdasarkan kondisi tertentu. Sesi B menambahkan baris yang memenuhi kondisi tersebut. | Jumlah baris yang terbaca dapat berubah. | Gunakan REPEATABLE READ atau SERIALIZABLE. |
| **Lost update** | Dua sesi membaca nilai yang sama lalu menulis perubahan masing-masing. | Perubahan salah satu sesi dapat tertimpa. | Gunakan FOR UPDATE atau pembaruan atomik. |
| **Write skew** | Dua transaksi membaca jumlah dokter aktif yang sama lalu menonaktifkan dokter berbeda. | Kedua transaksi bisa berhasil COMMIT, tetapi semua dokter menjadi tidak aktif. | Gunakan SERIALIZABLE atau penguncian yang sesuai. |
| **Read skew** | Satu transaksi membaca dua data terkait saat transaksi lain mengubah data di antaranya. | Data yang terbaca dapat berasal dari keadaan database berbeda. | Gunakan REPEATABLE READ. |

**Penjelasan:**

Setiap anomali terjadi karena interaksi antara pembacaan, perubahan data, dan urutan transaksi. Tingkat isolasi yang lebih tinggi dapat mencegah lebih banyak anomali, tetapi dapat meningkatkan kemungkinan transaksi dibatalkan atau perlu diulang.

Matriks di atas merangkum cara reproduksi dan mitigasi secara konseptual. Bukti pengujian yang benar-benar diperoleh dalam eksperimen ini terutama berasal dari Q24, Q26, dan Q27; anomali lainnya perlu diuji tersendiri jika laporan mensyaratkan bukti eksekusi untuk setiap baris.

---

### Q31 — Rekomendasi Isolation Level
Rekomendasikan isolation level untuk pembacaan sederhana yang dapat menerima perubahan antarpernyataan, laporan yang membutuhkan snapshot konsisten, dan transaksi dengan aturan bisnis lintas beberapa baris. Jelaskan kompromi dan risiko serialization failure.
>>
**Jawab:**
| Kebutuhan | Isolation level yang direkomendasikan | Alasan |
| --- | --- | --- |
| Pembacaan sederhana yang dapat menerima perubahan antarpernyataan | READ COMMITTED | Setiap pernyataan membaca data yang sudah di-commit pada snapshot pernyataan tersebut. |
| Laporan yang membutuhkan snapshot konsisten | REPEATABLE READ | Pembacaan dalam satu transaksi menggunakan snapshot yang konsisten sehingga perubahan yang di-commit oleh transaksi lain tidak mengubah snapshot tersebut. |
| Transaksi dengan aturan bisnis lintas beberapa baris | SERIALIZABLE | PostgreSQL mendeteksi konflik yang dapat menyebabkan anomali serialisasi dan dapat membatalkan transaksi yang berkonflik. |

**Penjelasan:**
1. READ COMMITTED cocok untuk operasi baca sehari-hari karena relatif fleksibel. Namun, hasil query yang sama dapat berubah jika transaksi lain melakukan perubahan dan COMMIT di antara kedua pembacaan.
2. REPEATABLE READ cocok untuk laporan yang harus membaca snapshot konsisten. Akan tetapi, isolation level ini di PostgreSQL masih dapat mengalami write skew, seperti yang dibuktikan pada Q26.
3. SERIALIZABLE cocok untuk aturan bisnis yang harus tetap benar meskipun beberapa transaksi berjalan bersamaan. Komprominya adalah PostgreSQL dapat menghasilkan serialization failure dengan SQLSTATE 40001, sehingga aplikasi harus siap mengulang seluruh transaksi dari awal.

**Kesimpulan:**
Isolation level perlu dipilih berdasarkan kebutuhan konsistensi. READ COMMITTED sesuai untuk pembacaan sederhana, REPEATABLE READ sesuai untuk laporan dengan snapshot konsisten, sedangkan SERIALIZABLE direkomendasikan untuk transaksi dengan aturan bisnis lintas beberapa baris yang tidak boleh dilanggar.

---

### Q32 — Tiga Pelajaran Utama dari Eksperimen
Tuliskan tiga pelajaran utama dari eksperimen. Setiap kesimpulan harus didukung bukti hasil query, urutan kejadian, atau pesan error, bukan hanya definisi teori.
>>
**Jawab:**
1. Penguncian baris membantu mengatur pembagian pekerjaan antarsesi.
Pada Q24, Sesi A mengunci pekerjaan dengan id = 1 menggunakan FOR UPDATE. Ketika Sesi B menjalankan FOR UPDATE SKIP LOCKED selagi kunci tersebut masih dipegang, Sesi B memperoleh pekerjaan dengan id = 2 dan id = 3, tanpa mengambil pekerjaan yang terkunci.

Hasil tersebut menunjukkan bahwa SKIP LOCKED berguna ketika beberapa worker mengambil pekerjaan dari antrean yang sama.

2. REPEATABLE READ belum tentu menjaga aturan bisnis lintas beberapa baris.
Pada Q26, Sesi A dan Sesi B sama-sama membaca jumlah dokter aktif sebanyak 2. Sesi A menonaktifkan Ani dan berhasil melakukan COMMIT. Setelah itu, Sesi B menonaktifkan Budi dan juga berhasil melakukan COMMIT.

Pemeriksaan akhir menunjukkan:
```
 dokter_id | nama | aktif
-----------+------+-------
         1 | Ani  | f
         2 | Budi | f
(2 rows)
```

Hasil ini membuktikan bahwa kedua transaksi dapat berhasil di-commit, tetapi aturan bisnis minimal satu dokter harus tetap aktif dilanggar.

3. SERIALIZABLE dapat mencegah write skew, tetapi aplikasi harus menangani kegagalan transaksi.
Pada Q27, kedua sesi membaca jumlah dokter aktif sebanyak 2. Sesi A berhasil menonaktifkan Ani dan melakukan COMMIT, sedangkan Sesi B gagal saat COMMIT dengan pesan:

```ERROR: could not serialize access due to read/write dependencies among transactions
DETAIL: Reason code: Canceled on identification as a pivot, during commit attempt.
HINT: The transaction might succeed if retried.
```

Pemeriksaan akhir menunjukkan Ani tidak aktif (f), sedangkan Budi tetap aktif (t). Hasil ini menunjukkan bahwa PostgreSQL membatalkan salah satu transaksi untuk mencegah keadaan yang melanggar aturan bisnis.

**Kesimpulan:**
Eksperimen menunjukkan bahwa penguncian dapat membantu mengatur akses terhadap baris, REPEATABLE READ tidak selalu mencegah write skew, dan SERIALIZABLE dapat mencegah anomali tersebut dengan membatalkan transaksi yang berkonflik. Karena itu, aplikasi perlu memilih isolation level sesuai kebutuhan dan menyediakan mekanisme retry untuk transaksi yang gagal akibat konflik serialisasi.