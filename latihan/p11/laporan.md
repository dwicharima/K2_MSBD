# Laporan Latihan Kelompok Pertemuan 11

| Nama                   | NIM       | Kontribusi |
|------------------------|-----------|------------|
| Agnes Natalia Siregar  | 251402108 | Langkah 1: Setup lingkungan pengujian, pengerjaan Q00 dan Q1–Q5 |
| Rasyd Arija A. Ritonga  | 251402020 |  |
| Abdullah Zufar Aulia   | 251402111 | |
| Fakhry Adrian Daulay   | 251402053 |  |
| Dwi Charima Husni      | 251402088 |  |

## Q1
-- Diminta: membuktikan REVOKE biasa pada pemilik bisa dibatalkan pemilik sendiri.
-- Dipilih: REVOKE lalu GRANT oleh skema_owner, supaya terlihat hak biasa vs hak kepemilikan.
-- Alternatif: hanya mengandalkan REVOKE; tidak dipilih karena tidak menutup K1.

Keluaran :
$ docker exec -i lab11-db psql -U postgres -d msbd < ../latihan/p11/q01_hak_pemilik.sql
REVOKE
SET
 peran_aktif 
-------------
 skema_owner
(1 row)

BEGIN
ERROR:  permission denied for table pelanggan
ROLLBACK
GRANT
BEGIN
UPDATE 1
ROLLBACK
RESET

Alasan :
Setelah REVOKE UPDATE, skema_owner ditolak (ERROR: permission denied for table pelanggan). Setelah GRANT UPDATE yang dijalankan skema_owner sendiri, UPDATE berhasil (UPDATE 1). Pemilik tabel selalu berwenang mengatur hak atas objeknya, termasuk memberikan hak apa pun kepada dirinya sendiri, sehingga REVOKE yang dijalankan terhadap pemilik hanya berlaku sampai pemilik menjalankan GRANT lagi. Kedua percobaan memakai ROLLBACK, jadi data tidak berubah.

## Q2 
-- Diminta: mencoba mencabut DROP dari pemilik dan mengutip galatnya.
-- Dipilih: REVOKE DROP apa adanya, supaya galat aslinya terlihat.
-- Alternatif: ALTER TABLE ... OWNER TO; itu memindahkan pemilik, bukan mencabut hak.

Keluaran :
$ docker exec -i lab11-db psql -U postgres -d msbd < ../latihan/p11/q02_drop_bukan_hak.sql
ERROR:  unrecognized privilege type "drop"

Alasan :
Galat yang keluar: ERROR: unrecognized privilege type "drop". Artinya DROP bukan jenis hak yang dikenal GRANT/REVOKE. Hak biasa (SELECT, INSERT, UPDATE, DELETE) adalah izin yang bisa diberikan dan dicabut per peran. Kemampuan DROP dan ALTER tidak berbentuk izin seperti itu, tetapi melekat pada status pemilik (atau anggota peran pemilik, atau superuser). Karena itu DROP tidak bisa dicabut dengan REVOKE.

## Q3
-- Diminta: memeriksa apakah tabel buatan postgres otomatis terbaca app_laporan.
-- Dipilih: has_table_privilege, supaya terbukti tanpa mengubah data.
-- Alternatif: SELECT langsung sebagai app_laporan; hasilnya sama tapi lebih berantakan.
--- Dijalankan sebagai postgres

Keluaran :
AGNES@LAPTOP-1T3ANVB7 MINGW64 /c/Semester 3/msbd-2026/lab11 (latihan/p11-keamanan)
$ docker exec -i lab11-db psql -U postgres -d msbd < ../latihan/p11/q03_default_privileges.sql
 peran_aktif 
-------------
 postgres
(1 row)

CREATE TABLE
 via_postgres 
--------------
 f
(1 row)

DROP TABLE
SET
CREATE TABLE
 via_skema_owner 
-----------------
 t
(1 row)

DROP TABLE
RESET

Alasan :
Tabel buatan postgres menghasilkan via_postgres = f, sedangkan tabel buatan skema_owner menghasilkan via_skema_owner = t. Penyebabnya, ALTER DEFAULT PRIVILEGES FOR ROLE skema_owner hanya berlaku untuk objek yang dibuat oleh skema_owner. Objek buatan postgres tidak terkena aturan itu, sehingga app_laporan tidak mendapat SELECT. Perintah yang seharusnya sudah dijalankan untuk peran pembuat objek tersebut:
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA lab11
GRANT SELECT ON TABLES TO app_read;
Praktik yang lebih baik, semua objek dibuat lewat SET ROLE skema_owner agar default privileges yang sama berlaku.

## Q4
-- Diminta: GRANT OPTION ke app_write, diteruskan ke app_analitik, lalu dicabut tanpa dan dengan CASCADE.
-- Dipilih: REVOKE GRANT OPTION FOR, supaya hanya hak meneruskan yang dicabut, bukan SELECT-nya.
-- Alternatif: REVOKE SELECT ... CASCADE; tidak dipilih karena mencabut SELECT app_write seluruhnya.

Keluaran :
AGNES@LAPTOP-1T3ANVB7 MINGW64 /c/Semester 3/msbd-2026/lab11 (latihan/p11-keamanan)
$ docker exec -i lab11-db psql -U postgres -d msbd < ../latihan/p11/q04_grant_option.sql
GRANT
SET
 peran_aktif 
-------------
 app_write
(1 row)

GRANT
RESET
 analitik | app_write 
----------+-----------
 t        | t
(1 row)

ERROR:  dependent privileges exist
HINT:  Use CASCADE to revoke them too.
REVOKE
 analitik | app_write 
----------+-----------
 f        | t
(1 row)

SET
 peran_aktif | baris_transaksi 
-------------+-----------------
 app_write   |          120000
(1 row)

RESET

Alasan :
Sebelum dicabut, app_analitik = t dan app_write = t. REVOKE GRANT OPTION FOR SELECT ... FROM app_write tanpa CASCADE ditolak dengan ERROR: dependent privileges exist (hint: Use CASCADE to revoke them too.), karena app_analitik masih memegang hak turunan dari app_write. Dengan CASCADE, hak turunan ikut dicabut, sehingga app_analitik = f. Hak SELECT milik app_write sendiri tetap ada (app_write = t), terbukti ia masih membaca 120000 baris transaksi, karena yang dicabut hanya kemampuan meneruskan hak, bukan haknya.

## Q5
-- Diminta: tabel tujuh peran, hak masing-masing, dan penanda login.
-- Dipilih: query katalog sistem (pg_roles, pg_auth_members, has_table_privilege), agar data dari sistem, bukan tebakan.
-- Alternatif: menulis tabel dari ingatan; tidak dipilih karena bisa meleset dari kondisi nyata.

Keluaran :
$ docker exec -i lab11-db psql -U postgres -d msbd < ../latihan/p11/q05_tabel_peran.sql
   rolname    | bisa_login | rolsuper | rolbypassrls 
--------------+------------+----------+--------------
 app_read     | f          | f        | f
 app_write    | f          | f        | f
 skema_owner  | f          | f        | f
 app_analitik | t          | f        | f
 app_auditor  | t          | f        | f
 app_laporan  | t          | f        | f
 app_portal   | t          | f        | f
(7 rows)

   anggota   |   induk   
-------------+-----------
 app_auditor | app_read
 app_laporan | app_read
 app_portal  | app_write
(3 rows)

    peran     | pel_sel | pel_ins | pel_upd | pel_del | akun_sel | trx_sel 
--------------+---------+---------+---------+---------+----------+---------
 skema_owner  | t       | t       | t       | t       | t        | t
 app_read     | t       | f       | f       | f       | t        | t
 app_write    | t       | t       | t       | t       | t        | t
 app_laporan  | t       | f       | f       | f       | t        | t
 app_portal   | t       | t       | t       | t       | t        | t
 app_analitik | f       | f       | f       | f       | f        | f
 app_auditor  | t       | f       | f       | f       | t        | t
(7 rows)

Alasan : 
Tujuh peran, diambil dari katalog sistem (app_auditor adalah peran ketujuh pilihan kelompok, karena modul hanya menyebut enam nama):
1. skema_owner
Login: Tidak   
Boleh apa: Pemilik tabel; semua hak, termasuk DROP, ALTER, dan GRANT.
2. app_read
Login: Tidak   
Boleh apa: Peran fungsional: SELECT pada pelanggan, akun, dan transaksi.
3. app_write
Login: Tidak   
Boleh apa: Peran fungsional: SELECT, INSERT, UPDATE, DELETE pada pelanggan; SELECT pada akun dan transaksi.
4. app_laporan
Login: Ya   
Boleh apa: Anggota app_read: hanya membaca.
5. app_laporan
Login: Ya   
Boleh apa: Anggota app_read: hanya membaca.
6. app_analitik
Login: Ya   
Boleh apa: Belum punya hak pada tabel mana pun (semua bernilai f).  
7. app_auditor
Login: Ya   
Boleh apa: Anggota app_read: hanya membaca.

Tidak ada peran yang berstatus superuser atau BYPASSRLS. Aplikasi tidak pernah login sebagai pemilik karena pemilik memegang hak yang tidak bisa dicabut (DROP, ALTER, GRANT), sehingga satu bug atau serangan pada aplikasi langsung berarti kehilangan seluruh tabel.

## Refleksi A
Pada Q1, hak biasa bisa dicabut dari pemilik, tetapi risikonya tetap ada. Jelaskan dari data mengapa “mencabut hak” bukan jalan keluar untuk keluhan K1, dan apa yang menjadi jalan keluarnya.
Jawaban : 
Data Q1 menunjukkan bahwa REVOKE UPDATE dari skema_owner memang membuat UPDATE ditolak (permission denied for table pelanggan). Tetapi satu GRANT UPDATE yang dijalankan skema_owner sendiri langsung mengembalikannya (UPDATE 1). Q2 memperlihatkan hal yang lebih mendasar: REVOKE DROP bahkan galat (unrecognized privilege type "drop"), karena kemampuan menghapus tabel melekat pada kepemilikan, bukan pada hak yang bisa dicabut.

Karena itu mencabut hak bukan jalan keluar untuk K1. Selama aplikasi login sebagai pemilik, bug seperti DROP TABLE di modul laporan tetap dipatuhi basis data, dan setiap pencabutan bisa dibatalkan oleh pemilik itu sendiri.

Jalan keluarnya memisahkan pemilik dari pemakai lewat peran berlapis. skema_owner memiliki tabel dan tidak pernah login. Hak dikumpulkan di peran fungsional (app_read, app_write) yang juga tidak login. Aplikasi login sebagai peran seperti app_laporan atau app_portal yang hanya meminjam hak dari lapis kedua. Data Q5 mendukung ini: tidak satu pun peran yang bisa login adalah pemilik, dan app_laporan hanya punya SELECT (pel_ins, pel_upd, pel_del bernilai f). Bila bug menjalankan DROP TABLE lewat peran itu, hasilnya hanya galat izin (must be owner of table), bukan tabel hilang.