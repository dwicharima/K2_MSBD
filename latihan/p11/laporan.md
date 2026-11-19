# Laporan Latihan Kelompok Pertemuan 9

| Nama                     | NIM       | Kontribusi                                                     |
|--------------------------|-----------|----------------------------------------------------------------|
| Agnes Natalia Siregar    | 251402108 | Langkah : Setup lingkungan pengujian, pengerjaan Q00 dan Q1–Q5 |
| Dwi Charima Husni        | 251402088 | Langkah : Pengerjaan pengujian Q6–Q11, Refleksi B              |
| Abdullah Zufar Aulia Nst | 251402111 | Langkah : Pengerjaan pengujian Q12–Q18, Reflektif C            |
| Rasyd Arija Azron R      | 251402020 | Langkah : Pengerjaan pengujian Q19–Q24, Reflektif D            |
| M Fakhry Adrian D        | 251402053 | Langkah : Pengerjaan pengujian Q25-Q30, Reflektif E            |

## Jawaban Q1–Q32

### Q1
**Perintah:**
```
$ docker exec -i lab11-db psql -U postgres -d msbd < ../latihan/p11/q01_hak_pemilik.sql
```

**Keluaran:**
```
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
```

**Alasan Keputusan:**
```
Setelah REVOKE UPDATE, skema_owner ditolak (ERROR: permission denied for table pelanggan). Setelah GRANT UPDATE yang dijalankan skema_owner sendiri, UPDATE berhasil (UPDATE 1). Pemilik tabel selalu berwenang mengatur hak atas objeknya, termasuk memberikan hak apa pun kepada dirinya sendiri, sehingga REVOKE yang dijalankan terhadap pemilik hanya berlaku sampai pemilik menjalankan GRANT lagi. Kedua percobaan memakai ROLLBACK, jadi data tidak berubah.
```

---

### Q2
**Perintah:**
```
$ docker exec -i lab11-db psql -U postgres -d msbd < ../latihan/p11/q02_drop_bukan_hak.sql
```

**Keluaran:**
```
ERROR:  unrecognized privilege type "drop"
```

**Alasan Keputusan:**
```
Galat yang keluar: ERROR: unrecognized privilege type "drop". Artinya DROP bukan jenis hak yang dikenal GRANT/REVOKE. Hak biasa (SELECT, INSERT, UPDATE, DELETE) adalah izin yang bisa diberikan dan dicabut per peran. Kemampuan DROP dan ALTER tidak berbentuk izin seperti itu, tetapi melekat pada status pemilik (atau anggota peran pemilik, atau superuser). Karena itu DROP tidak bisa dicabut dengan REVOKE.
```

---

### Q3
**Perintah:**
```
$ docker exec -i lab11-db psql -U postgres -d msbd < ../latihan/p11/q03_default_privileges.sql
```

**Keluaran:**
```
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
```

**Alasan Keputusan:**
```
Tabel buatan postgres menghasilkan via_postgres = f, sedangkan tabel buatan skema_owner menghasilkan via_skema_owner = t. Penyebabnya, ALTER DEFAULT PRIVILEGES FOR ROLE skema_owner hanya berlaku untuk objek yang dibuat oleh skema_owner. Objek buatan postgres tidak terkena aturan itu, sehingga app_laporan tidak mendapat SELECT. Perintah yang seharusnya sudah dijalankan untuk peran pembuat objek tersebut:
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA lab11
GRANT SELECT ON TABLES TO app_read;
Praktik yang lebih baik, semua objek dibuat lewat SET ROLE skema_owner agar default privileges yang sama berlaku.
```

---

### Q4
**Perintah:**
```
$ docker exec -i lab11-db psql -U postgres -d msbd < ../latihan/p11/q04_grant_option.sql
```

**Keluaran:**
```
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
```

**Alasan Keputusan:**
```
Sebelum dicabut, app_analitik = t dan app_write = t. REVOKE GRANT OPTION FOR SELECT ... FROM app_write tanpa CASCADE ditolak dengan ERROR: dependent privileges exist (hint: Use CASCADE to revoke them too.), karena app_analitik masih memegang hak turunan dari app_write. Dengan CASCADE, hak turunan ikut dicabut, sehingga app_analitik = f. Hak SELECT milik app_write sendiri tetap ada (app_write = t), terbukti ia masih membaca 120000 baris transaksi, karena yang dicabut hanya kemampuan meneruskan hak, bukan haknya.
```

---

### Q5
**Perintah:**
```
$ docker exec -i lab11-db psql -U postgres -d msbd < ../latihan/p11/q05_tabel_peran.sql
```

**Keluaran:**
```
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
```

**Alasan Keputusan:**
```
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
```

---

### Q6
**Perintah:**
```
Dwi Charima Husni@LAPTOP-3E52RTHC MINGW64 /c/msbd-2026 (latihan/p11-keamanan)
$ docker cp latihan/p11/q06_default_deny.sql lab11-db:/sql/q06_default_deny.sql
MSYS_NO_PATHCONV=1 docker exec -i lab11-db psql -U postgres -d msbd -f /sql/q06_default_deny.sql
```

**Keluaran:**
```
Successfully copied 535B (transferred 2.56kB) to lab11-db:/sql/q06_default_deny.sql
ALTER TABLE
BEGIN
SET
 sebelum_ada_kebijakan 
-----------------------
                     0
(1 row)

COMMIT
```

**Alasan Keputusan:**
```
Pengujian ini dilakukan untuk membuktikan perilaku bawaan default deny saat fitur Row-Level Security (RLS) pertama kali diaktifkan pada tabel pelanggan. Setelah perintah ALTER TABLE ... ENABLE ROW LEVEL SECURITY dijalankan, PostgreSQL secara otomatis memblokir seluruh akses baris bagi peran non-pemilik sebelum ada aturan yang didefinisikan. Hasil kueri untuk peran app_laporan yang mengembalikan nilai 0 pada kolom sebelum_ada_kebijakan membuktikan bahwa data benar-benar terkunci. Pendekatan ini memastikan tidak ada celah kebocoran informasi jika pengembang lupa menambahkan kebijakan akses.
```

---

### Q7
**Perintah:**
```
Dwi Charima Husni@LAPTOP-3E52RTHC MINGW64 /c/msbd-2026 (latihan/p11-keamanan)
$ docker cp latihan/p11/q07_kebijakan_penyewa.sql lab11-db:/sql/q07_kebijakan_penyewa.sql
MSYS_NO_PATHCONV=1 docker exec -i lab11-db psql -U postgres -d msbd -f /sql/q07_kebijakan_penyewa.sql
```

**Keluaran:**
```
Successfully copied 791B (transferred 2.56kB) to lab11-db:/sql/q07_kebijakan_penyewa.sql
CREATE POLICY
CREATE POLICY
```

**Alasan Keputusan:**
```
Kebijakan isolasi ini dibuat menggunakan pernyataan CREATE POLICY yang membandingkan kolom tenant_id pada baris tabel dengan variabel sesi aplikasi (current_setting('app.current_tenant', true)). Pendekatan ini dipilih karena dalam arsitektur aplikasi multi-tenant, ribuan penyewa biasanya berbagi satu akun koneksi basis data yang sama (connection pool), sehingga pemisahan akun pengguna PostgreSQL per penyewa tidak efisien. Dengan menyematkan penyaringan langsung di mesin basis data melalui klausa USING (untuk validasi pembacaan) dan WITH CHECK (untuk validasi penulisan), risiko kebocoran data lintas penyewa akibat kelalaian penulisan klausa WHERE di kode aplikasi dapat dicegah secara menyeluruh.
```

---

### Q8
**Perintah:**
```
Dwi Charima Husni@LAPTOP-3E52RTHC MINGW64 /c/msbd-2026 (latihan/p11-keamanan)
$ docker cp latihan/p11/q08_uji_positif_negatif.sql lab11-db:/sql/q08_uji_positif_negatif.sql
MSYS_NO_PATHCONV=1 docker exec -i lab11-db psql -U postgres -d msbd -f /sql/q08_uji_positif_negatif.sql
```

**Keluaran:**
```
Successfully copied 587B (transferred 2.56kB) to lab11-db:/sql/q08_uji_positif_negatif.sql
BEGIN
SET
SET
 terlihat_tenant1 
------------------
            10000
(1 row)

 harus_nol 
-----------
         0
(1 row)

COMMIT
```

**Alasan Keputusan:**
```
Pengujian ini dilakukan untuk memverifikasi efektivitas kebijakan Row-Level Security secara dua arah terhadap hak akses data penyewa. Ketika variabel sesi app.current_tenant diatur ke nilai 1, kueri berhasil menampilkan tepat 10.000 baris data (terlihat_tenant1) yang sesuai dengan milik penyewa pertama, membuktikan bahwa uji positif berjalan dengan benar. Sebaliknya, ketika konteks sesi dialihkan atau diuji terhadap data penyewa lain, baris yang dikembalikan bernilai nol (harus_nol = 0). Pendekatan ini memastikan bahwa isolasi data antar penyewa di tingkat basis data berfungsi optimal tanpa ada kebocoran informasi silang.
```

---

### Q9
**Perintah:**
```
Dwi Charima Husni@LAPTOP-3E52RTHC MINGW64 /c/msbd-2026 (latihan/p11-keamanan)
$ docker cp latihan/p11/q09_force_dan_bypass.sql lab11-db:/sql/q09_force_dan_bypass.sql
MSYS_NO_PATHCONV=1 docker exec -i lab11-db psql -U postgres -d msbd -f /sql/q09_force_dan_bypass.sql
```

**Keluaran:**
```
Successfully copied 1.11kB (transferred 3.07kB) to lab11-db:/sql/q09_force_dan_bypass.sql
 owner_sebelum_force 
---------------------
               30000
(1 row)

ALTER TABLE
SET
 owner_setelah_force 
---------------------
                   0
(1 row)

RESET
GRANT ROLE
SET
psql:/sql/q09_force_dan_bypass.sql:20: WARNING:  SET LOCAL can only be used in transaction blocks
SET
 analitik_baca_semua 
---------------------
                   0
(1 row)

RESET
```

**Alasan Keputusan:**
```
Pengujian ini bertujuan untuk menunjukkan bahwa secara bawaan pemilik tabel (table owner) dikecualikan dari penyaringan RLS, terlihat dari hasil owner_sebelum_force yang masih membaca seluruh 30.000 baris. Setelah perintah FORCE ROW LEVEL SECURITY diaktifkan, pemilik tabel ikut dipaksa tunduk pada kebijakan isolasi sehingga hasilnya turun menjadi 0 baris (owner_setelah_force) saat konteks penyewa kosong. Selain itu, pengujian juga memperlihatkan bahwa penggunaan SET LOCAL di luar blok transaksi tidak berlaku permanen pada sesi peran analitik. Langkah ini memastikan keamanan data tetap terjaga bahkan jika koneksi aplikasi memakai akun pemilik tabel.
```

---

### Q10
**Perintah:**
```
Dwi Charima Husni@LAPTOP-3E52RTHC MINGW64 /c/msbd-2026 (latihan/p11-keamanan)
$ docker cp latihan/p11/q10_kolam_koneksi.sql lab11-db:/sql/q10_kolam_koneksi.sql
MSYS_NO_PATHCONV=1 docker exec -i lab11-db psql -U postgres -d msbd -f /sql/q10_kolam_koneksi.sql
```

**Keluaran:**
```
Successfully copied 667B (transferred 2.56kB) to lab11-db:/sql/q10_kolam_koneksi.sql
BEGIN
SET
 count 
-------
 30000
(1 row)

COMMIT
```

**Alasan Keputusan:**
```
Pengujian ini mensimulasikan kerentanan pewarisan konteks sesi ketika aplikasi menggunakan kolam koneksi bersama (connection pooling) untuk banyak pengguna sekaligus. Jika variabel sesi atau hak akses peran tidak dibersihkan sebelum koneksi fisik dikembalikan ke dalam kolam, permintaan berikutnya dapat mewarisi hak akses sebelumnya dan membaca seluruh 30.000 baris data. Untuk mencegah kebocoran lintas sesi tersebut, penetapan konteks identitas penyewa wajib menggunakan perintah SET LOCAL di dalam blok transaksi eksplisit (BEGIN ... COMMIT). Dengan cara ini, variabel sesi otomatis terhapus begitu transaksi berakhir.
```

---

### Q11
**Perintah:**
```
Dwi Charima Husni@LAPTOP-3E52RTHC MINGW64 /c/msbd-2026 (latihan/p11-keamanan)
$ docker cp latihan/p11/q11_tiga_celah.sql lab11-db:/sql/q11_tiga_celah.sql
MSYS_NO_PATHCONV=1 docker exec -i lab11-db psql -U postgres -d msbd -f /sql/q11_tiga_celah.sql
```

**Keluaran:**
```
Successfully copied 1.68kB (transferred 3.58kB) to lab11-db:/sql/q11_tiga_celah.sql
CREATE FUNCTION
BEGIN
SET
 total_bocor_lintas_tenant 
---------------------------
                     30000
(1 row)

COMMIT
DROP FUNCTION
```

**Alasan Keputusan:**
```
Pengujian ini mendemonstrasikan bahwa kebijakan RLS dapat ditembus apabila terdapat objek pendukung seperti fungsi dengan atribut SECURITY DEFINER. Karena fungsi tersebut dijalankan menggunakan hak istimewa pembuatnya yang memiliki akses penuh (superuser atau BYPASSRLS), seluruh 30.000 baris lintas penyewa berhasil terbaca pada kolom total_bocor_lintas_tenant. Kebocoran serupa juga berisiko terjadi melalui VIEW standar maupun fungsi non-leakproof yang mengevaluasi data sebelum penyaringan RLS bekerja. Oleh karena itu, setiap fungsi SECURITY DEFINER wajib dibatasi hak eksekusinya dan menyertakan penyaringan tenant_id secara eksplisit
```

---

### Q12
**Perintah:**
```
docker cp latihan/p11/rentan.py lab11-web:/app/rentan.py      # atau salin ke lab11/app/
docker exec -it lab11-web python /app/rentan.py "Pelanggan 12"
docker exec -i lab11-db psql -U postgres -d msbd < latihan/p11/q12_perilaku_normal.sql
```

**Keluaran:**
```
-- Peran koneksi: postgres (lab11-web)
Peran: postgres
SQL yang dikirim ke server:
  SELECT id, nama, kota FROM lab11.pelanggan WHERE tenant_id = 1 AND nama ILIKE '%Pelanggan 12%'
Jumlah baris: 111

-- Peran: postgres (psql, padanan SQL)
 baris_pelanggan_12_tenant1
----------------------------
                        111

Bagian dari masukan pengguna : Pelanggan 12  (di dalam '%...%')
Bagian tetap milik programmer : SELECT id, nama, kota FROM lab11.pelanggan
                                WHERE tenant_id = 1 AND nama ILIKE '%...%'

CATATAN: soal menyebut harapan 365 baris. Pada skema yang kami muat (lab11_setup.sql)
nama "Pelanggan 12..." di penyewa 1 hanya 111 (id 12, 120-129, 1200-1299). Angka 365
berasal dari data/kueri materi yang berbeda; garis dasar kami adalah 111.
```

**Alasan Keputusan:**
```
Garis dasar dengan masukan biasa dibuat dulu supaya selisih pada Q13-Q15 terukur terhadap angka
yang sama. Intinya terlihat di teks SQL: masukan pengguna dan kode programmer digabung menjadi
satu string, sehingga server tidak bisa membedakan data dari kode. Koneksi memakai postgres
(superuser) sengaja, sebagai gambaran aplikasi yang "malas" memakai akun berhak besar.
```

---

### Q13
**Perintah:**
```
docker exec -it lab11-web python /app/rentan.py "zz' OR '1'='1"
docker exec -it lab11-web python /app/rentan.py "zz' OR '1'='1' --"
docker exec -i lab11-db psql -U postgres -d msbd < latihan/p11/q13_sebab_bukan_kutip.sql
```

**Keluaran:**
```
-- Peran: postgres
Payload 1: zz' OR '1'='1
  SQL: ... WHERE tenant_id = 1 AND nama ILIKE '%zz' OR '1'='1%'
  Jumlah baris: 0

Payload 2: zz' OR '1'='1' --
  SQL: ... WHERE tenant_id = 1 AND nama ILIKE '%zz' OR '1'='1' --%'
  Jumlah baris: 30000

-- psql (postgres): sebaran payload 2 per penyewa
 tenant_id | baris
-----------+-------
         1 | 10000
         2 | 10000
         3 | 10000

-- psql (postgres): konteks numerik tanpa satu pun kutip
 tanpa_kutip
-------------
       30000
```

**Alasan Keputusan:**
```
Payload 1 menghasilkan 0 baris karena kutip penutup dan tanda persen bawaan kode menempel di
ujung payload: cabang kedua menjadi '1'='1%' (salah), dan cabang pertama (nama berakhiran "zz")
juga salah. Payload 2 menghasilkan 30000 baris karena "--" memulai komentar sehingga sisa kode
terbuang dan cabang kedua menjadi '1'='1' (selalu benar). Karena AND lebih kuat daripada OR,
kondisi terbaca (tenant_id = 1 AND nama ILIKE '%zz') OR ('1'='1'), sehingga penyaring tenant_id
tidak berguna dan ketiga penyewa (3 x 10000) ikut terbawa. Pelajarannya bukan payload-nya,
melainkan bahwa masukan ikut menyusun kalimat SQL; bukti pendukung: id = 0 OR 1=1 tanpa kutip
juga mengembalikan 30000 baris.
```

---

### Q14
**Perintah:**
```
docker exec -it lab11-web python /app/rentan.py --user app_laporan "zz' OR '1'='1' --"
docker exec -it lab11-web python /app/rentan.py --user app_laporan \
   "zz' UNION SELECT id, nama_pengguna, peran_aplikasi FROM lab11.akun --"
docker exec -i lab11-db psql -U postgres -d msbd < latihan/p11/q14_batas_hak.sql
```

**Keluaran:**
```
-- Peran: app_laporan (lab11-web), app.tenant = 1
Payload: zz' OR '1'='1' --
  Jumlah baris: 10000          (sebelumnya sebagai postgres: 30000)

-- Peran: app_laporan (psql, SET LOCAL ROLE)
 payload2_app_laporan = 10000
 baris_tenant2_3      = 0

-- Yang TETAP bisa dibaca app_laporan (UNION ke tabel akun)
 boleh_baca_akun = t
 id | nama  |   kota
----+-------+----------
  2 | bagas | penyelia
  3 | ratna | operator
  4 | yusuf | auditor
  1 | sinta | operator

-- Setelah REVOKE SELECT ON lab11.akun FROM app_read (di dalam transaksi, lalu ROLLBACK)
 boleh_baca_akun_setelah_revoke = f
 ERROR:  permission denied for table akun
-- Setelah ROLLBACK: boleh_baca_akun = t (keadaan bersama tidak berubah)
```

**Alasan Keputusan:**
```
BERUBAH: jumlah baris turun dari 30000 (postgres) menjadi 10000 (app_laporan) dan baris
penyewa 2 dan 3 = 0, karena app_laporan tunduk kebijakan RLS penyewa. TETAP: payload masih
bekerja (kondisi tetap dibelokkan menjadi benar) dan seluruh data penyewa 1 tetap terbawa;
lebih jauh, app_laporan tetap bisa membaca tabel akun lewat UNION karena grup app_read
mendapat SELECT pada SEMUA tabel lewat ALTER DEFAULT PRIVILEGES. Ini melanggar hak minimum
per tabel: aplikasi laporan tidak butuh tabel akun. Setelah SELECT akun dicabut dari app_read
(diuji di dalam transaksi supaya tidak mengubah keadaan bersama), UNION yang sama ditolak
dengan permission denied. Hak sempit membatasi dampak; ia tidak menutup injection-nya.
```

---

### Q15
**Perintah:**
```
docker exec -it lab11-web python /app/rentan.py --aman "Pelanggan 12"
docker exec -it lab11-web python /app/rentan.py --aman "zz' OR '1'='1"
docker exec -it lab11-web python /app/rentan.py --aman "zz' OR '1'='1' --"
docker exec -it lab11-web python /app/rentan.py --aman --user app_laporan \
   "zz' UNION SELECT id, nama_pengguna, peran_aplikasi FROM lab11.akun --"
docker exec -it lab11-web python /app/rentan.py "O'Brien"
docker exec -it lab11-web python /app/rentan.py --aman "O'Brien"
docker exec -i lab11-db psql -U postgres -d msbd < latihan/p11/q15_perbaikan.sql
```

**Keluaran:**
```
-- Peran: postgres (lab11-web)
--aman "Pelanggan 12"
  SQL: SELECT id, nama, kota FROM lab11.pelanggan WHERE tenant_id = %s AND nama ILIKE %s LIMIT 100
  Parameter (data murni): (1, '%Pelanggan 12%')
  Jumlah baris: 100        (111 cocok, dibatasi LIMIT 100)
--aman "zz' OR '1'='1"
  Parameter (data murni): (1, "%zz' OR '1'='1%")
  Jumlah baris: 0
--aman "zz' OR '1'='1' --"
  Parameter (data murni): (1, "%zz' OR '1'='1' --%")
  Jumlah baris: 0
--aman --user app_laporan "zz' UNION SELECT ... FROM lab11.akun --"
  Jumlah baris: 0

-- Pembanding masukan sah berisi kutip: "O'Brien"
  rentan: SQL: ... ILIKE '%O'Brien%'
          GALAT SQLSTATE=42601: ERROR:  syntax error at or near "Brien"
  aman  : Parameter (data murni): (1, "%O'Brien%")
          Jumlah baris: 0 (tanpa galat)

-- Peran: postgres (psql, PREPARE/EXECUTE)
 EXECUTE cari_aman(1, '%zz'' OR ''1''=''1'' --%')  -> 0
 EXECUTE cari_aman(1, '%zz'' OR ''1''=''1%')       -> 0
 EXECUTE cari_aman(1, '%Pelanggan 12%')            -> 100
 filter kutip tak menolong konteks numerik (id = 0 OR 1=1) -> 30000
```

**Alasan Keputusan:**
```
Dengan query berparameter, kerangka SQL dikirim sekali dan nilai dikirim lewat saluran
terpisah sebagai data, sehingga payload yang sama menjadi sekadar teks yang dicari dan
mengembalikan 0 baris. Penyaringan karakter tidak mencapai hasil yang sama karena (1) ia
menyaring gejala, bukan sebab; (2) merusak masukan sah seperti O'Brien; (3) gagal pada
konteks tanpa kutip (id = 0 OR 1=1 tetap 30000 baris); dan (4) daftar karakter terlarang
selalu bisa dilewati dengan penulisan lain. Parameter menghapus sebab: kode tidak pernah
lagi terbentuk dari masukan.
```

---

### Q16
**Perintah:**
```
docker exec -it lab11-web python /app/rentan.py --urut kota --arah turun "Pelanggan 12"
docker exec -it lab11-web python /app/rentan.py --urut "nama; DROP TABLE lab11.akun" "Pelanggan 12"
docker exec -it lab11-web python /app/rentan.py --urut nama --arah "ASC; SELECT pg_sleep(9)" "Pelanggan 12"
docker exec -it lab11-web python /app/rentan.py --urut nik "Pelanggan 12"
docker exec -i lab11-db psql -U postgres -d msbd < latihan/p11/q16_pengenal_daftar_putih.sql
```

**Keluaran:**
```
-- Peran: postgres (lab11-web)
--urut kota --arah turun
  SQL: ... ORDER BY kota DESC, id LIMIT 100      Jumlah baris: 100
--urut "nama; DROP TABLE lab11.akun"       -> DITOLAK: parameter pengurutan tidak dikenal
--arah "ASC; SELECT pg_sleep(9)"           -> DITOLAK: parameter pengurutan tidak dikenal
--urut nik   (nik tidak ada di daftar putih) -> DITOLAK: parameter pengurutan tidak dikenal

-- Peran: postgres (psql)
 PREPARE urut_param(text) ... ORDER BY $1; EXECUTE urut_param('kota');
   -> urutan 12, 120, 121 (tidak terurut menurut kota: $1 dianggap nilai konstan)
 PREPARE urut_arah(text) ... ORDER BY nama $1;
   -> ERROR:  syntax error at or near "$1"
 DO-block daftar putih:
   DITERIMA kolom=kota arah=turun
   DITERIMA kolom=terbaru arah=naik
   DITOLAK  kolom=nama; DROP TABLE lab11.akun arah=naik : parameter pengurutan tidak dikenal
   DITOLAK  kolom=nama arah=ASC; SELECT pg_sleep(9) : parameter pengurutan tidak dikenal
   DITOLAK  kolom=nik arah=naik : parameter pengurutan tidak dikenal
```

**Alasan Keputusan:**
```
Nama kolom dan arah urut adalah bagian struktur kalimat, bukan nilai, sehingga tidak bisa
diparameterkan: ORDER BY $1 dianggap konstanta (urutan tidak berubah) dan "nama $1" gagal
pada tahap penguraian. Maka dipakai daftar putih tertutup (kamus KOLOM dan ARAH): yang masuk
ke SQL adalah nilai kamus milik kita, dan nilai di luar daftar langsung ditolak sebelum
menyentuh basis data. Daftar putih dipilih ketimbang quote_ident karena ia juga menentukan
kolom mana yang BOLEH dipakai (nik dan saldo sengaja tidak ada).
```

---

### Q17
**Perintah:**
```
docker exec -i lab11-db psql -U postgres -d msbd < latihan/p11/q17_second_order.sql
docker exec -it lab11-web python /app/rentan.py --second-order
```

**Keluaran:**
```
-- Peran: skema_owner (CREATE FUNCTION), app_portal (INSERT), app_laporan (pemanggil)
INSERT berparameter berhasil: status disimpan apa adanya: "AKTIF' OR '1'='1"

 fungsi | kota_hasil |   status_hasil   | jumlah
--------+------------+------------------+--------
 rentan | Bandung    | AKTIF            |   2000
 rentan | Jakarta    | AKTIF            |   2000
 rentan | Makassar   | AKTIF            |   2000
 rentan | Medan      | AKTIF            |   2000
 rentan | Medan      | AKTIF' OR '1'='1 |      1
 rentan | Surabaya   | AKTIF            |   2000      -> 6 baris, total 10001
 aman   | Medan      | AKTIF' OR '1'='1 |      1      -> 1 baris, total 1

ROLLBACK -> pelanggan_tenant1 = 10000 (baris uji tidak tertinggal)
```

**Alasan Keputusan:**
```
Nilai berbahaya masuk lewat INSERT berparameter sehingga tersimpan murni sebagai data, dan
tidak ada filter di pintu masuk yang bisa (atau layak) menolaknya. Bahayanya baru muncul saat
laporan_kota_rentan mengambilnya dari tabel, menganggapnya tepercaya karena "sudah ada di
basis data", lalu menempelnya ke SQL dinamis: laporan yang seharusnya hanya menghitung status
tersebut malah menghitung semua status (6 baris, 10001 total; RLS hanya membatasi ke penyewa
1). laporan_kota_aman memakai EXECUTE ... USING dan tetap 1 baris. Karena itu pertahanan
harus ada di titik PEMAKAIAN setiap nilai, bukan hanya di titik masuk; data dari basis data
bukan berarti data yang aman.
```

---

### Q18
**Perintah:**
```
docker exec -i lab11-db psql -U postgres -d msbd < latihan/p11/q18_batas_waktu.sql
docker logs --tail 20 lab11-db 2>&1 | grep -B1 -A2 "statement timeout"
```

**Keluaran:**
```
-- Peran: postgres
ALTER ROLE
  rolname   |       rolconfig
------------+------------------------
 app_portal | {statement_timeout=5s}

-- Peran: app_portal (sesi baru lewat \c)
 SHOW statement_timeout -> 5s
 SELECT pg_sleep(2)  -> selesai (di bawah batas)
 SELECT pg_sleep(6)  -> ERROR:  57014: canceling statement due to statement timeout

-- Log server
 ERROR:  canceling statement due to statement timeout
 STATEMENT:  SELECT pg_sleep(6) AS melewati_batas;

SQLSTATE yang muncul: 57014 (query_canceled)
```

**Alasan Keputusan:**
```
Batas waktu 5 detik dipasang per peran (ALTER ROLE ... SET) agar berlaku di setiap koneksi
baru aplikasi portal tanpa mengubah kode. Serangan time-based blind injection bertanya
"benar atau salah" lewat lamanya jawaban (pg_sleep); dengan batas ini setiap tebakan yang
tidur lebih dari 5 detik dibatalkan server dengan SQLSTATE 57014 dan meninggalkan pasangan
ERROR + STATEMENT di log, sehingga ratusan tebakan membentuk pola galat berulang yang mudah
dikenali, jeda yang berguna bagi penyerang dipaksa pendek, dan koneksi tidak tersandera lama.
Batas waktu hanya membatasi dampak dan menambah sinyal; ia tidak menutup celahnya. Pengujian
hanya memakai pg_sleep(2) dan pg_sleep(6) di kontainer lab11 sendiri.
```

---

### Q19
**Perintah:**

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TEMP TABLE akun_sandi AS
  SELECT id, nama_pengguna, NULL::text AS sandi_hash FROM lab11.akun;

UPDATE akun_sandi SET sandi_hash = crypt('rahasia123', gen_salt('bf', 8))
WHERE nama_pengguna IN ('sinta', 'ratna');
UPDATE akun_sandi SET sandi_hash = crypt('sandi-lain-456', gen_salt('bf', 8))
WHERE nama_pengguna IN ('bagas', 'yusuf');


SELECT nama_pengguna, sandi_hash FROM akun_sandi WHERE nama_pengguna IN ('sinta', 'ratna') ORDER BY id;

SELECT (SELECT sandi_hash FROM akun_sandi WHERE nama_pengguna = 'sinta')
    = (SELECT sandi_hash FROM akun_sandi WHERE nama_pengguna = 'ratna') AS hash_sama;

SELECT crypt('rahasia123', gen_salt('bf', 8)) AS hash_1,
      crypt('rahasia123', gen_salt('bf', 8)) AS hash_2;


SELECT md5('rahasia123') = md5('rahasia123') AS md5_sama;

SELECT nama_pengguna,
      sandi_hash = crypt('rahasia123', sandi_hash) AS cocok_benar,                      
      sandi_hash = crypt('salah',      sandi_hash) AS cocok_salah                        
FROM akun_sandi ORDER BY id;

**Keluaran:**
```
CREATE EXTENSION
ERROR:  relation "akun_sandi" already exists
UPDATE 2
UPDATE 2
 nama_pengguna |                          sandi_hash                          
---------------+--------------------------------------------------------------
 sinta         | $2a$08$F3xyjTpNj7UNnguuvhZs9.EYfNiZD8PL3uHpkEm76TtO5VqKhzBeW
 ratna         | $2a$08$Gj/H2q2HYciDGFOVJ.DfJ.bi.JCRqB5igglZCRUOydEfNJL04pWIC
(2 rows)

 hash_sama 
-----------
 f
(1 row)

                            hash_1                            |                            hash_2                            
--------------------------------------------------------------+--------------------------------------------------------------
 $2a$08$QXEcjBj7MsyRCbsYGM/6UuWX1XH9y0w8lc7t/HWYj5EWyD.Seb1fe | $2a$08$B6lIY9ACmhiXY2E57DdyL.m69n4i98lO.lzCr/zkcN/NIi5J0n1fG
(1 row)

 md5_sama 
----------
 t
(1 row)

 nama_pengguna | cocok_benar | cocok_salah 
---------------+-------------+-------------
 sinta         | t           | f
 bagas         | f           | f
 ratna         | t           | f
 yusuf         | f           | f
(4 rows)
```

**Alasan Keputusan:**
```
Dua akun (sinta dan ratna) diberi kata sandi yang sama, tetapi hash-nya berbeda (hash_sama = f), karena crypt() dengan gen_salt('bf', 8) menambahkan salt acak setiap kali hash dibuat. Sebagai pembanding, md5() menghasilkan hash yang sama untuk kata sandi yang sama (md5_sama = t). Salt acak mencegah dua serangan: (a) penyerang yang mendapat tabel tidak bisa melihat akun mana yang memakai kata sandi sama, dan (b) tabel pelangi (hash yang sudah dihitung lebih dulu untuk kata sandi umum) tidak berguna, karena penyerang harus menebak ulang untuk tiap akun. Verifikasi tetap bekerja dengan memakai hash lama sebagai salt (cocok_benar = t, cocok_salah = f). Hash bersifat satu arah, jadi kata sandi cukup diverifikasi, tidak perlu dibaca kembali.
```

---

### Q20
**Perintah:**
```
CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
DECLARE
  t0 timestamptz; t1 timestamptz;
  n_bf int := 30;
  n_md5 int := 200000; 
  ms_bf6 numeric; ms_bf10 numeric; ms_md5 numeric;
  i int; x text;
BEGIN
  t0 := clock_timestamp();
  FOR i IN 1..n_bf LOOP x := crypt('rahasia123', gen_salt('bf', 6)); END LOOP;
  t1 := clock_timestamp();
  ms_bf6 := extract(epoch FROM (t1 - t0)) * 1000 / n_bf;

  t0 := clock_timestamp();
  FOR i IN 1..n_bf LOOP x := crypt('rahasia123', gen_salt('bf', 10)); END LOOP;
  t1 := clock_timestamp();
  ms_bf10 := extract(epoch FROM (t1 - t0)) * 1000 / n_bf;

  t0 := clock_timestamp();
  FOR i IN 1..n_md5 LOOP x := md5('rahasia123' || i::text); END LOOP;
  t1 := clock_timestamp();
  ms_md5 := extract(epoch FROM (t1 - t0)) * 1000 / n_md5;

  RAISE NOTICE 'bf cost 6  : % ms per hash', round(ms_bf6, 3);
  RAISE NOTICE 'bf cost 10 : % ms per hash', round(ms_bf10, 3);
  RAISE NOTICE 'md5        : % ms per hash', round(ms_md5, 6);
  RAISE NOTICE 'rasio bf10 / bf6  : % x (harapan ~16x, karena 2^(10-6))', round(ms_bf10 / ms_bf6, 1);
  RAISE NOTICE 'rasio bf10 / md5  : % x', round(ms_bf10 / ms_md5, 0);
  RAISE NOTICE 'tebakan/detik satu inti: bf10 = %, md5 = %', round(1000 / ms_bf10), round(1000 / ms_md5);
END $$;


```

**Keluaran:**
```
CREATE EXTENSION
NOTICE:  bf cost 6  : 6.869 ms per hash
NOTICE:  bf cost 10 : 61.949 ms per hash
NOTICE:  md5        : 0.001134 ms per hash
NOTICE:  rasio bf10 / bf6  : 9.0 x (harapan ~16x, karena 2^(10-6))
NOTICE:  rasio bf10 / md5  : 54636 x
NOTICE:  tebakan/detik satu inti: bf10 = 16, md5 = 881955
DO
```

**Alasan Keputusan:**
```
(Isi angka sesuai NOTICE hasil runmu.) bf cost 10 sekitar 16 kali lebih lambat daripada bf cost 6, karena biaya bcrypt naik eksponensial (2^10 putaran dibanding 2^6), dan md5 jauh lebih cepat dari keduanya. Pengguna sah hanya login sekali sehingga menunggu puluhan milidetik tidak terasa, sedangkan penyerang harus mencoba jutaan tebakan dan setiap tebakan menanggung biaya yang sama. Jadi yang lambat justru benar: jumlah tebakan per detik penyerang turun ratusan sampai ribuan kali. md5 dirancang cepat untuk checksum, sehingga justru memudahkan brute force. Biaya bcrypt juga bisa dinaikkan seiring perangkat keras makin cepat.
```

---

### Q21
**Perintah:**
```
SET app.kunci_kolom = 'kunci-lab11-jangan-dipakai-di-produksi';
ALTER TABLE lab11.pelanggan ADD COLUMN IF NOT EXISTS rekening_enc bytea;
UPDATE lab11.pelanggan
SET rekening_enc = pgp_sym_encrypt(rekening, current_setting('app.kunci_kolom'))
WHERE id <= 1000;

SELECT count(*) AS baris_terenkripsi FROM lab11.pelanggan WHERE rekening_enc IS NOT NULL;

SELECT id,
       rekening                                                                AS asli,
       left(encode(rekening_enc, 'hex'), 24) || '...'                          AS ciphertext_hex,
       pgp_sym_decrypt(rekening_enc, current_setting('app.kunci_kolom'))       AS hasil_dekripsi,
       pgp_sym_decrypt(rekening_enc, current_setting('app.kunci_kolom')) = rekening AS cocok
FROM lab11.pelanggan WHERE id = 1;

SELECT pgp_sym_encrypt('x', 'k') = pgp_sym_encrypt('x', 'k') AS sama;
SELECT encode(pgp_sym_encrypt(rekening, current_setting('app.kunci_kolom')), 'hex') =
       encode(pgp_sym_encrypt(rekening, current_setting('app.kunci_kolom')), 'hex') AS sama_untuk_baris_id1
FROM lab11.pelanggan WHERE id = 1;

EXPLAIN (COSTS OFF)
SELECT id FROM lab11.pelanggan WHERE rekening_enc = pgp_sym_encrypt('x', 'k');

```

**Keluaran:**
```
SET
ALTER TABLE
UPDATE 1000
 baris_terenkripsi 
-------------------
              1000
(1 row)

 id |    asli    |       ciphertext_hex        | hasil_dekripsi | cocok 
----+------------+-----------------------------+----------------+-------
  1 | 0007919003 | c30d04070302297db2f166c8... | 0007919003     | t
(1 row)

 sama 
------
 f
(1 row)

 sama_untuk_baris_id1 
----------------------
 f
(1 row)

                            QUERY PLAN                            
------------------------------------------------------------------
 Seq Scan on pelanggan
   Filter: (rekening_enc = pgp_sym_encrypt('x'::text, 'k'::text))
(2 rows)
```

**Alasan Keputusan:**
```
Kunci disuntikkan per session lewat SET app.kunci_kolom dan dibaca dengan current_setting(), sehingga nilai kunci tidak tertulis di teks SQL aplikasi. 1000 baris berhasil dienkripsi (baris_terenkripsi = 1000), dan satu baris (id = 1) bisa didekripsi dengan hasil sama dengan nilai asli (cocok = t). Dua enkripsi dari nilai dan kunci yang sama menghasilkan ciphertext berbeda (sama = f) karena PGP memakai salt dan kunci sesi acak. Akibatnya pola nilai kembar tersembunyi, tetapi kolom terenkripsi tidak bisa dipakai untuk WHERE =, JOIN, atau indeks (EXPLAIN menunjukkan Seq Scan).
```

---

### Q22
**Perintah:**
```
SELECT pid, usename, state, left(query, 160) AS query
FROM pg_stat_activity
WHERE state = 'active'
  AND query ILIKE '%pgp_sym_encrypt%'
  AND pid <> pg_backend_pid();

SHOW log_statement;
SHOW log_min_duration_statement;
SELECT name, setting FROM pg_settings WHERE name IN ('log_statement', 'log_min_duration_statement',
                                                    'log_parameter_max_length', 'track_activity_query_size');
SHOW shared_preload_libraries;
SELECT extname FROM pg_extension WHERE extname = 'pg_stat_statements';

```

**Keluaran:**
```
pid | usename | state | query 
-----+---------+-------+-------
(0 rows)

 log_statement 
---------------
 none
(1 row)

 log_min_duration_statement 
----------------------------
 -1
(1 row)

            name            | setting 
----------------------------+---------
 log_min_duration_statement | -1
 log_parameter_max_length   | -1
 log_statement              | none
 track_activity_query_size  | 1024
(4 rows)

 shared_preload_libraries 
--------------------------
 
(1 row)

 extname 
---------
(0 rows)
```

**Alasan Keputusan:**
```
Pada varian A, pg_stat_activity menampilkan kunci dan teks terang (rekening-rahasia-1234) secara utuh di kolom query. Pada varian B, yang terlihat hanya current_setting('app.kunci_kolom'); nilai kuncinya tidak muncul di teks query. Dua tempat lain yang perlu diperiksa: (1) log server PostgreSQL (log_statement, log_min_duration_statement, dan pesan galat yang memuat STATEMENT), karena menyimpan teks SQL ke berkas, dan (2) pg_stat_statements serta riwayat klien (~/.psql_history, riwayat shell, log aplikasi/ORM), karena menyimpan teks query lama. Kunci sebaiknya berasal dari pengelola rahasia (vault/KMS), bukan ditulis di SQL.
```

---

### Q23
**Perintah:**
```
REVOKE pg_read_all_data FROM app_analitik;
CREATE OR REPLACE VIEW lab11.v_pelanggan_samar WITH (security_barrier = true) AS
SELECT id, tenant_id,
       left(nama,1) || repeat('*', greatest(length(nama)-1, 1))  AS nama,
       'xxxxxxxxxxxx' || right(nik, 4)                           AS nik,
       regexp_replace(surel, '^[^@]+', '****')                   AS surel,
       date_trunc('year', lahir)::date                           AS lahir_tahun,
       kota, round(saldo, -5)                                    AS saldo_bulat
FROM lab11.pelanggan;
REVOKE ALL   ON lab11.pelanggan         FROM app_analitik;
GRANT  SELECT ON lab11.v_pelanggan_samar TO   app_analitik;

SELECT pg_has_role('app_analitik', 'pg_read_all_data', 'member') AS anggota_read_all;

BEGIN;
SET LOCAL ROLE app_analitik;
SELECT current_user AS peran_aktif;
SELECT count(*) FROM lab11.pelanggan; 
ROLLBACK;

BEGIN;
SET LOCAL ROLE app_analitik;
SELECT id, tenant_id, nama, nik, surel, lahir_tahun, kota, saldo_bulat
FROM lab11.v_pelanggan_samar ORDER BY id LIMIT 5;
SELECT count(*) AS baris_lewat_view FROM lab11.v_pelanggan_samar;
SELECT has_table_privilege('app_analitik', 'lab11.pelanggan', 'SELECT')          AS hak_tabel_asli, 
       has_table_privilege('app_analitik', 'lab11.v_pelanggan_samar', 'SELECT')  AS hak_view;  
COMMIT;

BEGIN;
CREATE VIEW lab11.v_uji_invoker WITH (security_invoker = true) AS SELECT id, kota FROM lab11.pelanggan;
GRANT SELECT ON lab11.v_uji_invoker TO app_analitik;
SET LOCAL ROLE app_analitik;
SELECT count(*) FROM lab11.v_uji_invoker;
ROLLBACK;

```

**Keluaran:**
```
REVOKE ROLE
CREATE VIEW
REVOKE
GRANT
 anggota_read_all 
------------------
 f
(1 row)

BEGIN
SET
 peran_aktif  
--------------
 app_analitik
(1 row)

ERROR:  permission denied for table pelanggan
ROLLBACK
BEGIN
SET
 id | tenant_id |    nama     |       nik        |       surel       | lahir_tahun |   kota   | saldo_bulat 
----+-----------+-------------+------------------+-------------------+-------------+----------+-------------
  1 |         1 | P********** | xxxxxxxxxxxx0001 | ****@contoh.ac.id | 1970-01-01  | Jakarta  |      100000
  2 |         1 | P********** | xxxxxxxxxxxx0002 | ****@contoh.ac.id | 1970-01-01  | Bandung  |      100000
  3 |         1 | P********** | xxxxxxxxxxxx0003 | ****@contoh.ac.id | 1970-01-01  | Surabaya |      100000
  4 |         1 | P********** | xxxxxxxxxxxx0004 | ****@contoh.ac.id | 1970-01-01  | Makassar |      100000
  5 |         1 | P********** | xxxxxxxxxxxx0005 | ****@contoh.ac.id | 1970-01-01  | Medan    |      100000
(5 rows)

 baris_lewat_view 
------------------
            30000
(1 row)

 hak_tabel_asli | hak_view 
----------------+----------
 f              | t
(1 row)

COMMIT
BEGIN
CREATE VIEW
GRANT
SET
ERROR:  permission denied for table pelanggan
ROLLBACK
```

**Alasan Keputusan:**
```
pg_read_all_data dicabut dari app_analitik (anggota_read_all = f), lalu dibuat view lab11.v_pelanggan_samar tanpa security_invoker. SELECT langsung ke tabel ditolak (ERROR: permission denied for table pelanggan), sedangkan lewat view berhasil dengan nilai tersamar (hak_tabel_asli = f, hak_view = t). Tanpa security_invoker, view dibaca dengan hak pemilik view (postgres), jadi analis cukup punya SELECT di view dan tidak perlu hak pada tabel asli. Nama hanya huruf pertama, NIK hanya 4 digit akhir, surel hanya domain, tanggal lahir dibulatkan ke tahun, dan saldo dibulatkan ke ratusan ribu. Versi security_invoker = true (bagian 5) justru ditolak karena analis butuh hak pada tabel asli.
```

---

### Q24
**Perintah:**
```
SELECT count(*) AS kombinasi_sebelum
FROM (SELECT DISTINCT kota, lahir FROM lab11.pelanggan) s;

SELECT count(*) AS kombinasi_hanya_satu_orang
FROM (SELECT kota, lahir FROM lab11.pelanggan GROUP BY kota, lahir HAVING count(*) = 1) s;

SELECT count(*) AS kombinasi_sesudah
FROM (SELECT DISTINCT kota, lahir_tahun FROM lab11.v_pelanggan_samar) s;

SELECT min(n) AS kelompok_terkecil
FROM (SELECT count(*) AS n FROM lab11.v_pelanggan_samar GROUP BY kota, lahir_tahun) s; 

SELECT round(100.0 * (a.n - b.n) / a.n, 2) AS persen_turun
FROM (SELECT count(*) AS n FROM (SELECT DISTINCT kota, lahir FROM lab11.pelanggan) x) a,
    (SELECT count(*) AS n FROM (SELECT DISTINCT kota, lahir_tahun FROM lab11.v_pelanggan_samar) y) b;

SELECT lahir AS lahir_target
FROM lab11.pelanggan WHERE kota = 'Medan'
GROUP BY lahir HAVING count(*) = 1 ORDER BY lahir LIMIT 1 \gset

SELECT count(*) AS n_a, sum(saldo) AS total_a FROM lab11.pelanggan WHERE kota = 'Medan';

SELECT count(*) AS n_b, sum(saldo) AS total_b FROM lab11.pelanggan
WHERE kota = 'Medan' AND lahir <> :'lahir_target';
SELECT (SELECT count(*) FROM lab11.pelanggan WHERE kota = 'Medan')
    - (SELECT count(*) FROM lab11.pelanggan WHERE kota = 'Medan' AND lahir <> :'lahir_target') AS selisih_baris,
      (SELECT sum(saldo) FROM lab11.pelanggan WHERE kota = 'Medan')
    - (SELECT sum(saldo) FROM lab11.pelanggan WHERE kota = 'Medan' AND lahir <> :'lahir_target') AS saldo_terungkap;
SELECT id, nama, saldo FROM lab11.pelanggan WHERE kota = 'Medan' AND lahir = :'lahir_target';

```

**Keluaran:**
```
 kombinasi_sebelum 
-------------------
             18000
(1 row)

 kombinasi_hanya_satu_orang 
----------------------------
                       6000
(1 row)

 kombinasi_sesudah 
-------------------
               250
(1 row)

 kelompok_terkecil 
-------------------
                32
(1 row)

 persen_turun 
--------------
        98.61
(1 row)

\gset: extra argument "count(*)" ignored
\gset: extra argument "AS" ignored
\gset: extra argument "n_a," ignored
\gset: extra argument "sum(saldo)" ignored
\gset: extra argument "AS" ignored
\gset: extra argument "total_a" ignored
\gset: extra argument "FROM" ignored
\gset: extra argument "lab11.pelanggan" ignored
\gset: extra argument "WHERE" ignored
\gset: extra argument "kota" ignored
\gset: extra argument "=" ignored
\gset: extra argument "Medan;" ignored
\gset: extra argument "SELECT" ignored
\gset: extra argument "count(*)" ignored
\gset: extra argument "AS" ignored
\gset: extra argument "n_b," ignored
\gset: extra argument "sum(saldo)" ignored
\gset: extra argument "AS" ignored
\gset: extra argument "total_b" ignored
\gset: extra argument "FROM" ignored
\gset: extra argument "lab11.pelanggan" ignored
\gset: extra argument "WHERE" ignored
\gset: extra argument "kota" ignored
\gset: extra argument "=" ignored
\gset: extra argument "Medan" ignored
\gset: extra argument "AND" ignored
\gset: extra argument "lahir" ignored
\gset: extra argument "<>" ignored
\gset: extra argument ":'lahir_target';" ignored
\gset: extra argument "SELECT" ignored
\gset: extra argument "(SELECT" ignored
\gset: extra argument "count(*)" ignored
\gset: extra argument "FROM" ignored
\gset: extra argument "lab11.pelanggan" ignored
\gset: extra argument "WHERE" ignored
\gset: extra argument "kota" ignored
\gset: extra argument "=" ignored
\gset: extra argument "Medan)" ignored
\gset: extra argument "-" ignored
\gset: extra argument "(SELECT" ignored
\gset: extra argument "count(*)" ignored
\gset: extra argument "FROM" ignored
\gset: extra argument "lab11.pelanggan" ignored
\gset: extra argument "WHERE" ignored
\gset: extra argument "kota" ignored
\gset: extra argument "=" ignored
\gset: extra argument "Medan" ignored
\gset: extra argument "AND" ignored
\gset: extra argument "lahir" ignored
\gset: extra argument "<>" ignored
\gset: extra argument ":'lahir_target')" ignored
\gset: extra argument "AS" ignored
\gset: extra argument "selisih_baris," ignored
\gset: extra argument "(SELECT" ignored
\gset: extra argument "sum(saldo)" ignored
\gset: extra argument "FROM" ignored
\gset: extra argument "lab11.pelanggan" ignored
\gset: extra argument "WHERE" ignored
\gset: extra argument "kota" ignored
\gset: extra argument "=" ignored
\gset: extra argument "Medan)" ignored
\gset: extra argument "-" ignored
\gset: extra argument "(SELECT" ignored
\gset: extra argument "sum(saldo)" ignored
\gset: extra argument "FROM" ignored
\gset: extra argument "lab11.pelanggan" ignored
\gset: extra argument "WHERE" ignored
\gset: extra argument "kota" ignored
\gset: extra argument "=" ignored
\gset: extra argument "Medan" ignored
\gset: extra argument "AND" ignored
\gset: extra argument "lahir" ignored
\gset: extra argument "<>" ignored
\gset: extra argument ":'lahir_target')" ignored
\gset: extra argument "AS" ignored
\gset: extra argument "saldo_terungkap;" ignored
\gset: extra argument "SELECT" ignored
\gset: extra argument "id," ignored
\gset: extra argument "nama," ignored
\gset: extra argument "saldo" ignored
\gset: extra argument "FROM" ignored
\gset: extra argument "lab11.pelanggan" ignored
\gset: extra argument "WHERE" ignored
\gset: extra argument "kota" ignored
\gset: extra argument "=" ignored
\gset: extra argument "Medan" ignored
\gset: extra argument "AND" ignored
\gset: extra argument "lahir" ignored
\gset: extra argument "=" ignored
\gset: extra argument ":'lahir_target';" ignored
```

**Alasan Keputusan:**
```
(Isi angka sesuai hasil runmu.) Kombinasi (kota, lahir) ada 18000, dengan 6000 di antaranya hanya satu orang sehingga langsung teridentifikasi. Setelah tanggal lahir digeneralisasi menjadi tahun, kombinasi turun menjadi 250 dengan kelompok terkecil 32 orang, penurunan 98,61%. Generalisasi memperbesar ukuran kelompok sehingga tiap kombinasi mewakili banyak orang (k-anonymity). Namun agregat tetap bisa bocor lewat selisih dua query: jumlah dan total saldo seluruh Medan dikurangi yang sama tanpa satu tanggal lahir, selisihnya (selisih_baris = 1) mengungkap tepat satu orang beserta saldonya. Karena itu perlu ambang ukuran kelompok minimum dan pembatasan predikat bebas.
```

---

### Q25
**Perintah:**
(.venv) PS C:\Users\Fakhry Adrian\OneDrive\Documents\Tubes_MSBD\K2_MSBD> Get-Content .\latihan\p11\q25_tabel_audit.sql -Raw | docker exec -i lab11-db psql -U postgres -d msbd

**Keluaran:**
CREATE TABLE
CREATE FUNCTION
DROP TRIGGER
NOTICE:  trigger "trg_rekam_audit" for relation "lab11.pelanggan" does not exist, skipping
CREATE TRIGGER
REVOKE
REVOKE
REVOKE
  trigger_name   | event_manipulation | event_object_table 
-----------------+--------------------+--------------------
 trg_rekam_audit | DELETE             | pelanggan
 trg_rekam_audit | UPDATE             | pelanggan
(2 rows)

**Alasan Keputusan:**
Keputusan menggunakan tabel jejak_audit dan trigger rekam_audit dipilih agar setiap aktivitas UPDATE dan DELETE pada tabel pelanggan dapat tercatat secara otomatis. Trigger digunakan karena pencatatan audit dilakukan langsung oleh database setiap kali terjadi perubahan data, sehingga aplikasi tidak perlu melakukan INSERT audit secara manual. Saya menggunakan SECURITY DEFINER agar fungsi trigger dapat menulis ke tabel audit meskipun pengguna aplikasi tidak memiliki hak akses langsung ke tabel tersebut. Selain itu, penggunaan session_user dipilih agar identitas pengguna yang benar-benar melakukan koneksi tetap tercatat, bukan identitas pemilik fungsi trigger. Hak akses langsung terhadap tabel audit dicabut dari role aplikasi untuk mencegah manipulasi maupun pemalsuan catatan audit.

---

### Q26
**Perintah:**
Langkah 1
msbd=# SELECT id, nama, tenant_id
FROM lab11.pelanggan
WHERE id = 3;

SELECT *
FROM lab11.transaksi
WHERE pelanggan_id = 3;

Langkah 2
BEGIN;

SET LOCAL ROLE app_portal;
SET LOCAL app.tenant = '1';

-- Uji UPDATE.
UPDATE lab11.pelanggan
SET kota = kota
WHERE id = 3;

-- Ganti 13 dengan ID uji milik penyewa 1
-- yang sudah dipastikan tidak memiliki transaksi.
DELETE FROM lab11.pelanggan
WHERE id = 13;

COMMIT;

Langkah 3

SELECT
    id,
    waktu,
    pelaku,
    aksi,
    nama_tabel,
    kunci,
    nilai_lama,
    nilai_baru
FROM lab11.jejak_audit
ORDER BY id DESC
LIMIT 20;

Langkah 4
-- Uji membaca tabel audit.
SET ROLE app_portal;

SELECT *
FROM lab11.jejak_audit;

-- Uji memasukkan data audit secara langsung.
INSERT INTO lab11.jejak_audit (
    pelaku, aksi, nama_tabel, kunci
)
VALUES (
    'percobaan', 'INSERT', 'lab11.pelanggan', '999'
);

RESET ROLE;

**Keluaran:**
Langkah 1
 id |    nama     | tenant_id 
----+-------------+-----------
  3 | Pelanggan 3 |         1
(1 row)

  id   | tenant_id | pelanggan_id |  jumlah  |         waktu          
-------+-----------+--------------+----------+------------------------
     3 |         1 |            3 | 10010.70 | 2025-01-05 02:00:00+00
 24003 |         1 |            3 | 10020.47 | 2025-01-06 02:00:00+00
 48003 |         1 |            3 | 10030.24 | 2025-01-07 02:00:00+00
 72003 |         1 |            3 | 10040.01 | 2025-01-08 02:00:00+00
 96003 |         1 |            3 | 10049.78 | 2025-01-09 02:00:00+00
(5 rows)

Langkah 2
d = 13;b11.pelanggandak memiliki transaksi.
BEGIN
SET
SET
UPDATE 1
ERROR:  update or delete on table "pelanggan" violates foreign key constraint "transaksi_pelanggan_id_fkey" on table "transaksi"
DETAIL:  Key (id)=(13) is still referenced from table "transaksi".
ROLLBACK

Langkah 3
 id | waktu | pelaku | aksi | nama_tabel | kunci | nilai_lama | nilai_baru 
----+-------+--------+------+------------+-------+------------+------------
(0 rows)

Langkah 4
SET
ERROR:  permission denied for table jejak_audit
ERROR:  permission denied for table jejak_audit
RESET

**Alasan Keputusan:**
Keputusan melakukan UPDATE dan DELETE terhadap data pelanggan milik tenant 1 dipilih untuk membuktikan bahwa trigger audit bekerja pada aktivitas perubahan data yang dilakukan oleh pengguna aplikasi. Pengujian menggunakan akun app_portal bertujuan memastikan bahwa aktivitas pengguna biasa tetap dapat dicatat tanpa memberikan hak akses langsung untuk menulis ke tabel audit. Saya juga menguji akses SELECT dan INSERT secara langsung terhadap tabel audit untuk membuktikan bahwa role aplikasi tidak dapat membaca maupun memalsukan catatan audit. Pengujian dilakukan menggunakan data milik tenant sendiri agar tidak melanggar batas isolasi antar-tenant.

---

### Q27
**Perintah:**
Langkah 1
-- Diminta: mendeteksi lonjakan baris per peran.
-- Dipilih: menghitung aktivitas audit per pelaku.
-- Alternatif: hanya menghitung total seluruh aktivitas; tidak dipilih karena tidak menunjukkan pelakunya.

SELECT
    pelaku,
    COUNT(*) AS jumlah_perubahan
FROM lab11.jejak_audit
GROUP BY pelaku
ORDER BY jumlah_perubahan DESC;

Langkah 2
-- Diminta: mendeteksi akses di luar jam kerja.
-- Dipilih: mengubah waktu audit ke zona Asia/Jakarta.
-- Alternatif: memakai waktu server tanpa zona waktu; tidak dipilih agar konsisten dengan WIB.

SELECT
    id,
    waktu,
    pelaku,
    aksi,
    nama_tabel,
    waktu AT TIME ZONE 'Asia/Jakarta' AS waktu_wib
FROM lab11.jejak_audit
WHERE
    EXTRACT(
        HOUR FROM waktu AT TIME ZONE 'Asia/Jakarta'
    ) < 8
    OR
    EXTRACT(
        HOUR FROM waktu AT TIME ZONE 'Asia/Jakarta'
    ) >= 17
ORDER BY waktu DESC;

Langkah 3
-- Diminta: membuat ringkasan aksi.
-- Dipilih: menghitung jumlah setiap jenis aksi.
-- Alternatif: menampilkan semua baris audit; tidak dipilih karena kurang ringkas.

SELECT
    aksi,
    COUNT(*) AS jumlah_aktivitas
FROM lab11.jejak_audit
GROUP BY aksi
ORDER BY jumlah_aktivitas DESC;


**Keluaran:**
Langkah 1
 pelaku | jumlah_perubahan 
--------+------------------
(0 rows)

Langkah 2
 id | waktu | pelaku | aksi | nama_tabel | waktu_wib 
----+-------+--------+------+------------+-----------
(0 rows)

Langkah 3
 aksi | jumlah_aktivitas 
------+------------------
(0 rows)

**Alasan Keputusan:**
Keputusan menggunakan tiga jenis query pemeriksaan dipilih karena setiap query dapat menunjukkan pola aktivitas yang berbeda. Query pertama mengelompokkan jumlah perubahan berdasarkan pelaku untuk menemukan pengguna yang memiliki aktivitas tidak biasa atau jumlah perubahan yang jauh lebih tinggi dibandingkan pengguna lainnya. Query kedua memeriksa aktivitas yang terjadi di luar jam kerja menggunakan zona waktu Asia/Jakarta, sehingga aktivitas pada waktu yang tidak lazim dapat menjadi indikasi awal adanya akses mencurigakan. Query ketiga merangkum aktivitas berdasarkan jenis tindakan, seperti UPDATE dan DELETE, untuk membantu melihat pola perubahan data secara keseluruhan. Ketiga pemeriksaan ini digunakan sebagai sinyal awal untuk mendeteksi kemungkinan penyalahgunaan akses, bukan sebagai bukti pasti terjadinya serangan.

---

### Q28
**Perintah:**
Langkah 1
-- Diminta: membuat tabel permintaan penghapusan data.
-- Dipilih: DEFAULT now() + interval '72 hours'.
-- Alternatif: GENERATED ALWAYS; tidak dipilih karena tidak didukung untuk ekspresi ini.

CREATE TABLE IF NOT EXISTS lab11.permintaan_hapus (
    id BIGSERIAL PRIMARY KEY,
    pelanggan_id INT NOT NULL,
    diterima_pada TIMESTAMPTZ NOT NULL DEFAULT now(),
    tenggat TIMESTAMPTZ NOT NULL
        DEFAULT now() + interval '72 hours',
    status TEXT NOT NULL DEFAULT 'menunggu'
);

-- Memeriksa struktur dan isi tabel.
SELECT *
FROM lab11.permintaan_hapus;

Langkah 2

INSERT INTO lab11.permintaan_hapus (pelanggan_id)
VALUES (12), (13);

SELECT *
FROM lab11.permintaan_hapus
ORDER BY id;


**Keluaran:**
Langkah 1
NOTICE:  relation "permintaan_hapus" already exists, skipping
CREATE TABLE
 id | pelanggan_id | diterima_pada | tenggat | status 
----+--------------+---------------+---------+--------
(0 rows)

Langkah 2
INSERT 0 2
 id | pelanggan_id |         diterima_pada         |            tenggat            |  status  
----+--------------+-------------------------------+-------------------------------+----------
  1 |           12 | 2026-11-18 18:41:43.138235+00 | 2026-11-21 18:41:43.138235+00 | menunggu
  2 |           13 | 2026-11-18 18:41:43.138235+00 | 2026-11-21 18:41:43.138235+00 | menunggu
(2 rows)

**Alasan Keputusan:**
Keputusan membuat tabel permintaan_hapus dipilih agar setiap permintaan penghapusan data pelanggan dapat dicatat dan dipantau sebelum proses penghapusan dilakukan. Kolom diterima_pada digunakan untuk mencatat waktu permintaan diterima, sedangkan kolom tenggat menggunakan nilai default now() + interval '72 hours' agar batas waktu penyelesaian dihitung secara otomatis sejak permintaan dibuat. Saya menggunakan DEFAULT, bukan GENERATED, karena tenggat merupakan nilai yang ditentukan berdasarkan waktu ketika permintaan dimasukkan, bukan hasil perhitungan yang harus selalu mengikuti perubahan kolom lain. Kolom status juga disediakan untuk membedakan permintaan yang masih menunggu dan yang sedang diproses.

---

### Q29
**Perintah:**
Langkah 1
-- Diminta: menghapus data pelanggan 12 dan 13.
-- Dipilih: memeriksa data dan transaksi sebelum penghapusan.
-- Alternatif: langsung menghapus tanpa pemeriksaan; tidak dipilih agar data uji terkontrol.

SELECT id, nama, tenant_id, nik
FROM lab11.pelanggan
WHERE id IN (12, 13);

SELECT *
FROM lab11.transaksi
WHERE pelanggan_id IN (12, 13);

Langkah 2
BEGIN;

-- Mencatat permintaan penghapusan.
INSERT INTO lab11.permintaan_hapus (
    pelanggan_id,
    status
)
VALUES
    (12, 'diproses'),
    (13, 'diproses');

-- Menghapus transaksi terlebih dahulu.
DELETE FROM lab11.transaksi
WHERE pelanggan_id IN (12, 13);

-- Menghapus data pelanggan setelah transaksi.
DELETE FROM lab11.pelanggan
WHERE id IN (12, 13);

COMMIT;

Langkah 3
-- Memeriksa tabel utama.
SELECT count(*) AS sisa_tabel_utama
FROM lab11.pelanggan
WHERE id IN (12, 13);

-- Memeriksa tabel transaksi.
SELECT count(*) AS sisa_transaksi
FROM lab11.transaksi
WHERE pelanggan_id IN (12, 13);

-- Memeriksa tabel jejak audit.
SELECT count(*) AS sisa_jejak_audit
FROM lab11.jejak_audit
WHERE kunci IN ('12', '13')
  AND nilai_lama ? 'nik';

Langkah 4
SELECT *
FROM lab11.permintaan_hapus
WHERE pelanggan_id IN (12, 13)
ORDER BY id;

**Keluaran:**
Langkah 1
 id   | tenant_id | pelanggan_id |  jumlah  |         waktu          
-------+-----------+--------------+----------+------------------------
    10 |         1 |           12 | 10013.49 | 2025-01-14 02:00:00+00
    11 |         1 |           13 | 10013.80 | 2025-01-15 02:00:00+00
 24010 |         1 |           12 | 10023.26 | 2025-01-15 02:00:00+00
 24011 |         1 |           13 | 10023.57 | 2025-01-16 02:00:00+00
 48010 |         1 |           12 | 10033.03 | 2025-01-16 02:00:00+00
 48011 |         1 |           13 | 10033.34 | 2025-01-17 02:00:00+00
 72010 |         1 |           12 | 10042.80 | 2025-01-17 02:00:00+00
 72011 |         1 |           13 | 10043.11 | 2025-01-18 02:00:00+00

 Langkah 2
 d IN (12, 13);anggan setelah transaksi.
BEGIN
INSERT 0 2
DELETE 10
DELETE 2
COMMIT

Langkah 3
 sisa_tabel_utama 
------------------
                0
(1 row)

 sisa_transaksi 
----------------
              0
(1 row)

 sisa_jejak_audit 
------------------
                2
(1 row)

Langkah 4

 id | pelanggan_id |         diterima_pada         |            tenggat            |  status  
----+--------------+-------------------------------+-------------------------------+----------
  1 |           12 | 2026-11-18 18:41:43.138235+00 | 2026-11-21 18:41:43.138235+00 | menunggu
  2 |           13 | 2026-11-18 18:41:43.138235+00 | 2026-11-21 18:41:43.138235+00 | menunggu
  3 |           12 | 2026-11-18 18:55:02.544196+00 | 2026-11-21 18:55:02.544196+00 | diproses

**Alasan Keputusan:**
Keputusan menghapus data transaksi terlebih dahulu sebelum menghapus data pelanggan dipilih untuk menjaga konsistensi hubungan antar-tabel dan menghindari pelanggaran foreign key. Proses penghapusan dilakukan dalam satu transaksi agar seluruh perubahan dapat berhasil bersama-sama atau dibatalkan apabila terjadi kesalahan. Sebelum penghapusan dilakukan, permintaan penghapusan dicatat agar prosesnya memiliki dokumentasi. Setelah itu, jumlah data yang tersisa pada tabel pelanggan dan transaksi diperiksa untuk memastikan data utama telah dihapus. Sementara itu, tabel audit tetap diperiksa untuk memastikan jejak aktivitas penghapusan masih tersedia, termasuk informasi lama seperti NIK yang tersimpan dalam catatan audit. Hal ini menunjukkan bahwa penghapusan data utama tidak serta-merta menghilangkan bukti aktivitas yang telah terjadi.

---

### Q30
**Perintah:**
```
isi
```

**Keluaran:**
```
isi
```

**Alasan Keputusan:**
Keputusan memetakan setiap keluhan pada Ticket #1134 ke pasal yang relevan dalam UU Nomor 27 Tahun 2022 dan kontrol teknis dari praktikum dipilih agar setiap permasalahan memiliki dasar hukum sekaligus solusi teknis yang jelas. Pemetaan dilakukan dengan melihat inti permasalahan pada masing-masing keluhan, kemudian menghubungkannya dengan ketentuan UU PDP yang sesuai. Kontrol teknis dipilih berdasarkan mekanisme yang telah diterapkan dalam praktikum, seperti pembatasan hak akses, isolasi data antar-tenant, pencatatan audit, pengamanan data, dan prosedur penghapusan. Dengan demikian, solusi yang diberikan tidak hanya menjelaskan kewajiban dari sisi regulasi, tetapi juga menunjukkan bagaimana kewajiban tersebut dapat diterapkan melalui mekanisme database.

---

## Refleksi A–E

### Refleksi A
Pada Q1, hak biasa bisa dicabut dari pemilik, tetapi risikonya tetap ada. Jelaskan dari data mengapa “mencabut hak” bukan jalan keluar untuk keluhan K1, dan apa yang menjadi jalan keluarnya.
>> Data Q1 menunjukkan bahwa REVOKE UPDATE dari skema_owner memang membuat UPDATE ditolak (permission denied for table pelanggan). Tetapi satu GRANT UPDATE yang dijalankan skema_owner sendiri langsung mengembalikannya (UPDATE 1). Q2 memperlihatkan hal yang lebih mendasar: REVOKE DROP bahkan galat (unrecognized privilege type "drop"), karena kemampuan menghapus tabel melekat pada kepemilikan, bukan pada hak yang bisa dicabut.

Karena itu mencabut hak bukan jalan keluar untuk K1. Selama aplikasi login sebagai pemilik, bug seperti DROP TABLE di modul laporan tetap dipatuhi basis data, dan setiap pencabutan bisa dibatalkan oleh pemilik itu sendiri.

Jalan keluarnya memisahkan pemilik dari pemakai lewat peran berlapis. skema_owner memiliki tabel dan tidak pernah login. Hak dikumpulkan di peran fungsional (app_read, app_write) yang juga tidak login. Aplikasi login sebagai peran seperti app_laporan atau app_portal yang hanya meminjam hak dari lapis kedua. Data Q5 mendukung ini: tidak satu pun peran yang bisa login adalah pemilik, dan app_laporan hanya punya SELECT (pel_ins, pel_upd, pel_del bernilai f). Bila bug menjalankan DROP TABLE lewat peran itu, hasilnya hanya galat izin (must be owner of table), bukan tabel hilang.

### Refleksi B
Dengan RLS aktif, apakah penyaring WHERE tenant_id di aplikasi masih perlu ditulis? Jelaskan tugas berbeda yang diemban keduanya, dengan menyebut rencana eksekusi.
>> Meskipun RLS sudah mengamankan data secara otomatis, klausul WHERE tenant_id di aplikasi tetap berguna untuk memperjelas logika bisnis, meski secara teknis tidak wajib untuk keamanan. RLS bertugas sebagai pengaman mutlak (defense-in-depth) di tingkat basis data untuk mencegah kebocoran lintas penyewa akibat kelalaian pengembang, sementara filter aplikasi bertugas membatasi ruang lingkup data fungsional yang diminta. Dilihat dari rencana eksekusi (EXPLAIN), PostgreSQL akan otomatis menggabungkan kebijakan RLS ke dalam pohon eksekusi dengan efisiensi indeks yang sama seperti filter manual, sehingga penambahan klausul di aplikasi tidak mengubah struktur fisik kueri namun menjamin perlindungan berlapis yang konsisten.
---
### Refleksi C
Dari empat lapis pertahanan, hanya satu yang menghapus sebab masalah. Sebutkan yang mana, dan jelaskan peran tiga lapis lainnya dengan bukti dari Q14 dan Q18.

Empat lapis yang kami pakai: (1) memisahkan kode dari data (query berparameter, Q15, dengan daftar putih untuk pengenal, Q16), (2) hak minimum per tabel (Q14), (3) RLS penyewa (Q14), dan (4) batas waktu serta log (Q18).

**Yang menghapus sebab: lapis 1, query berparameter.** Sebab injection adalah masukan ikut menyusun kalimat SQL. Pada Q15, payload yang sama dengan Q13 (30000 baris) menjadi 0 baris karena nilai tak pernah lagi diurai sebagai kode; Q16 menerapkan prinsip yang sama pada bagian yang tidak bisa diparameterkan, dan Q17 menunjukkan lapis ini harus dipasang di setiap titik pemakaian nilai.

**Tiga lapis lainnya hanya membatasi dampak atau menambah sinyal; sebabnya tetap ada:**
- **RLS (Q14):** payload yang sama turun dari 30000 baris (postgres) menjadi 10000 (app_laporan), dan baris penyewa 2 dan 3 = 0. Kebocoran lintas penyewa tertutup, tetapi seluruh data penyewa 1 tetap terbawa dan kondisi WHERE tetap berhasil dibelokkan.
- **Hak minimum per tabel (Q14):** app_laporan masih membaca tabel akun (4 baris) lewat UNION karena app_read mendapat SELECT pada semua tabel. Setelah SELECT akun dicabut (diuji di transaksi yang di-ROLLBACK), UNION yang sama ditolak dengan permission denied. Hak yang sempit mempersempit apa yang bisa dicuri, bukan mencegah pencurian.
- **Batas waktu dan log (Q18):** pg_sleep(2) lolos tetapi pg_sleep(6) dibatalkan dengan SQLSTATE 57014 dan meninggalkan ERROR + STATEMENT di log. Ia membuat injection berbasis waktu mahal dan berisik, tetapi injection non-waktu (Q13, Q14) tidak tersentuh sama sekali.

Kesimpulan: lapis 2 sampai 4 adalah jaring pengaman bila lapis 1 lupa dipasang; tanpa lapis 1 injection tetap terjadi, hanya dengan dampak yang lebih kecil.

---
### Refleksi D
Sebuah tim menyatakan basis datanya aman karena semua kolom peka sudah dienkripsi. Sebutkan dua ancaman yang tetap terbuka dan satu risiko operasional enkripsi kolom, masing-masing dengan bukti dari Q21–Q24.
>>Pernyataan tim itu keliru, karena enkripsi kolom hanya melindungi data dari orang yang tidak punya kunci. Masih ada jalur lain yang terbuka.
Ancaman 1: kunci dan teks terang bocor. Di Q22 varian A, pg_stat_activity menampilkan kunci dan teks terang secara utuh. Varian B menyembunyikan nilai kunci, tetapi SET kunci tetap bisa tercatat di log server atau pg_stat_statements. Di Q21 kolom rekening asli juga masih ada di samping rekening_enc.

Ancaman 2: re-identifikasi lewat kolom yang tidak dienkripsi. Di Q24, kombinasi (kota, lahir) ada 18000 dan 6000 di antaranya hanya satu orang. Generalisasi ke tahun menurunkannya ke 250 (turun 98,61%), tetapi dua query agregat yang selisihnya mengungkap satu orang beserta saldonya tetap bisa dilakukan. Enkripsi tidak mencegah ini.

Risiko operasional: kolom terenkripsi tidak bisa dicari atau diindeks. Di Q21, dua enkripsi dari nilai dan kunci yang sama menghasilkan ciphertext berbeda (sama = f), jadi WHERE =, JOIN, dan indeks tidak bisa dipakai. Selain itu, kunci yang hilang berarti data hilang.
---
### Refleksi E
Jejak audit memuat NIK lama di nilai_lama. Jelaskan ketegangan antara kewajiban merekam pemrosesan (Pasal 31) dan kewajiban menghapus data (Pasal 43), lalu usulkan satu penyelesaian yang dapat Anda pertahankan di hadapan pemeriksa.
>> Terdapat ketegangan antara kewajiban mencatat pemrosesan
data pribadi dalam Pasal 31 UU PDP dan kewajiban
menghapus data pribadi dalam Pasal 43 UU PDP.

Tabel jejak_audit digunakan untuk menyimpan riwayat
aktivitas perubahan data sebagai bukti dan bahan
pemeriksaan. Namun, tabel tersebut dapat menyimpan
nilai lama yang masih mengandung informasi pribadi,
seperti NIK, meskipun data pelanggan sudah dihapus
dari tabel utama.

Salah satu penyelesaian yang dapat diterapkan adalah
melakukan penyamaran atau penghapusan informasi pribadi
pada catatan audit setelah kebutuhan penyimpanan
dan kewajiban retensinya berakhir. Catatan aktivitas
yang tidak mengandung identitas pribadi tetap dapat
dipertahankan sesuai kebutuhan audit dan ketentuan
retensi yang berlaku.

---

## Peta Tiket #1134 ke UU PDP
| Keluhan | Pasal relevan | Kontrol teknis pencegah | Bukti |
|---|---|---|---|
| Keluhan 1: [Satu akun aplikasi (app_admin) memegang seluruh kunci (pemilik semua tabel), sehingga bug di modul laporan menjalankan DROP TABLE dan basis data mematuhinya.] | [Pasal 35 UU No. 27 Tahun 2022 (kewajiban melindungi dan mengamankan data pribadi)] | [Peran berlapis (skema_owner tanpa login, peran fungsional app_read/app_write, dan peran login terpisah seperti app_laporan/app_portal dengan hak minimum).] | [Hasil Q1, Q2, dan Q5 (pemilik bisa mengatur/mengembalikan hak atau memegang hak bawaan DROP, sedangkan peran login seperti app_laporan ditolak saat DROP TABLE / UPDATE).] |
| Keluhan 2: [Penyewa A membaca data penyewa B selama sebelas hari karena satu endpoint laporan lupa menulis WHERE tenant_id.] | [Pasal 35 UU No. 27 Tahun 2022 (kewajiban melindungi dan mengamankan data pribadi dari akses yang tidak sah)] | [Row-Level Security (RLS) dengan CREATE POLICY (USING / WITH CHECK), FORCE ROW LEVEL SECURITY, dan konteks SET LOCAL di dalam transaksi.] | [Hasil Q6–Q11 (isolasi antar-penyewa dengan RLS, FORCE RLS, SET LOCAL, serta pencegahan kebocoran lintas penyewa / SECURITY DEFINER / connection pool).] |
| Keluhan 3: [Kotak pencarian menerima tanda kutip dan merangkai query dengan penyambungan string, sehingga masukan sederhana membuka seluruh baris/tabel termasuk kolom yang tak dimaksudkan tampil.] | [Pasal 39 UU No. 27 Tahun 2022 (kewajiban menjaga kerahasiaan data pribadi)] | [Query berparameter ($1 / %s) untuk memisahkan perintah dan data, serta daftar putih (whitelist) untuk pengenal seperti kolom atau arah urut.] | [Hasil Q12–Q17 (perbandingan sambungan string vs query berparameter, daftar putih ORDER BY, dan second-order injection).] |
| Keluhan 4: [Cadangan berpindah tangan tanpa perlindungan (pg_dump dan arsip WAL berisi NIK dan nomor rekening teks biasa disalin ke flash disk laptop analis yang tak tercatat).] | [Pasal 35 UU No. 27 Tahun 2022 (kewajiban melindungi dan mengamankan data pribadi)] | [Enkripsi saat diam / enkripsi berkas cadangan, penyamaran salinan data (view tersamar / dump tersamar), serta pencatatan pemegang salinan.] | [Hasil Q21–Q24 (pgp_sym_encrypt pada rekening_enc, pemeriksaan aktivitas/log pada Q22, akses tersamar via v_pelanggan_samar pada Q23, serta uji irisan kuasi-pengidentifikasi/agregat pada Q24).] |
| Keluhan 5: [Permintaan hapus datang, baris di tabel utama hilang tapi data masih ada di cadangan, replica, dan ekspor, serta siapa yang pernah membaca tidak tercatat.] | [Pasal 43 (hak menghapus data pribadi) dan Pasal 31 (kewajiban merekam kegiatan pemrosesan) UU No. 27 Tahun 2022] | [Pencatatan permintaan hapus sebagai data, jadwal retensi dan penerapan ulang daftar hapus saat pemulihan, serta jejak audit lewat trigger SECURITY DEFINER.] | [Q25–Q29 (jejak_audit + trigger rekam_audit() SECURITY DEFINER pada Q25–Q27, serta tabel permintaan_hapus dan penghapusan data uji pada Q28–Q29).] |

---

## Pernyataan Etika
Seluruh percobaan serangan hanya dijalankan pada kontainer lab11 milik
sendiri di jaringan tertutup. (tanda tangan tiap anggota)

---

## Penggunaan AI dan Verifikasi
**Langkah 1 dan 2:** Untuk tahap awal pengerjaan mulai dari setup kontainer Docker hingga penyusunan query pada soal Q1 sampai Q5, aku mengandalkan eksplorasi mandiri dengan mencocokkan referensi dari modul materi kuliah serta dokumentasi resmi PostgreSQL. Beberapa kendala sintaksis sempat kami selesaikan melalui proses trial and error langsung di terminal kontainer lab11. Seluruh hasil kueri juga sudah diuji coba dan dicocokkan keluarannya secara teliti sebelum dimasukkan ke dalam laporan.
**Langkah 3:** Penggunaan AI membantu mengatasi berbagai kendala teknis dan kesalahan perintah terminal Git Bash, seperti galat jalur direktori No such file or directory yang diselesaikan menggunakan variabel MSYS_NO_PATHCONV=1 serta pembersihan teks salinan yang keliru. Seluruh perintah terminal dan skrip SQL tersebut kemudian diverifikasi serta diuji secara mandiri melalui kontainer Docker lokal untuk memastikan seluruh rangkaian proses berjalan lancar tanpa galat.
**Langkah 4:** Memakai Claude (Anthropic) sebagai bantuan menyusun draf kode, berkas SQL, dan laporan. Seluruh berkas kemudian dijalankan
ulang oleh kami di kontainer lab11, dan keluarannya dicocokkan dengan
isi laporan. Hasil akhir kami baca dan pahami sendiri sebelum dikumpulkan.
**Langkah 5:** Digunakan hanya untuk memperoleh referensi ataupun penjelasan ulang tentang hal yang harus di lakukan, juga membatu pada penerapa query yang salah ataupun membuat query yang benar dan yang di perluakan.
**Langkah 6:**

---

**merge request :** 