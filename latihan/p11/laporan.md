# Laporan Latihan Kelompok Pertemuan 9

| Nama                     | NIM       | Kontribusi                                                     |
|--------------------------|-----------|----------------------------------------------------------------|
| Agnes Natalia Siregar    | 251402108 | Langkah : Setup lingkungan pengujian, pengerjaan Q00 dan Q1–Q5 |
| Dwi Charima Husni        | 251402088 | Langkah : Pengerjaan pengujian Q6–Q11, Refleksi B              |
| Abdullah Zufar Aulia Nst | 251402111 | Langkah : Pengerjaan pengujian Q12–Q18, Reflektif C            |
|                          | 251402    | Langkah : Pengerjaan pengujian Q19–Q24, Reflektif D            |
|                          | 251402    | Langkah : Pengerjaan pengujian Q25-Q30, Reflektif E            |

## Jawaban Q1–Q32

### Q1
**Perintah:**
```
isi
```

**Keluaran:**
```
isi
```

**Alasan Keputusan:**
```
isi
```

---

### Q2
**Perintah:**
```
isi
```

**Keluaran:**
```
isi
```

**Alasan Keputusan:**
```
isi
```

---

### Q3
**Perintah:**
```
isi
```

**Keluaran:**
```
isi
```

**Alasan Keputusan:**
```
isi
```

---

### Q4
**Perintah:**
```
isi
```

**Keluaran:**
```
isi
```

**Alasan Keputusan:**
```
isi
```

---

### Q5
**Perintah:**
```
isi
```

**Keluaran:**
```
isi
```

**Alasan Keputusan:**
```
isi
```

---

### Q6
**Perintah:**
```
isi
```

**Keluaran:**
```
isi
```

**Alasan Keputusan:**
```
isi
```

---

### Q7
**Perintah:**
```
isi
```

**Keluaran:**
```
isi
```

**Alasan Keputusan:**
```
isi
```

---

### Q8
**Perintah:**
```
isi
```

**Keluaran:**
```
isi
```

**Alasan Keputusan:**
```
isi
```

---

### Q9
**Perintah:**
```
isi
```

**Keluaran:**
```
isi
```

**Alasan Keputusan:**
```
isi
```

---

### Q10
**Perintah:**
```
isi
```

**Keluaran:**
```
isi
```

**Alasan Keputusan:**
```
isi
```

---

### Q11
**Perintah:**
```
isi
```

**Keluaran:**
```
isi
```

**Alasan Keputusan:**
```
isi
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
```
isi
```

**Keluaran:**
```
isi
```

**Alasan Keputusan:**
```
isi
```

---

### Q20
**Perintah:**
```
isi
```

**Keluaran:**
```
isi
```

**Alasan Keputusan:**
```
isi
```

---

### Q21
**Perintah:**
```
isi
```

**Keluaran:**
```
isi
```

**Alasan Keputusan:**
```
isi
```

---

### Q22
**Perintah:**
```
isi
```

**Keluaran:**
```
isi
```

**Alasan Keputusan:**
```
isi
```

---

### Q23
**Perintah:**
```
isi
```

**Keluaran:**
```
isi
```

**Alasan Keputusan:**
```
isi
```

---

### Q24
**Perintah:**
```
isi
```

**Keluaran:**
```
isi
```

**Alasan Keputusan:**
```
isi
```

---

### Q25
**Perintah:**
```
isi
```

**Keluaran:**
```
isi
```

**Alasan Keputusan:**
```
isi
```

---

### Q26
**Perintah:**
```
isi
```

**Keluaran:**
```
isi
```

**Alasan Keputusan:**
```
isi
```

---

### Q27
**Perintah:**
```
isi
```

**Keluaran:**
```
isi
```

**Alasan Keputusan:**
```
isi
```

---

### Q28
**Perintah:**
```
isi
```

**Keluaran:**
```
isi
```

**Alasan Keputusan:**
```
isi
```

---

### Q29
**Perintah:**
```
isi
```

**Keluaran:**
```
isi
```

**Alasan Keputusan:**
```
isi
```

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
```
isi
```

---

## Refleksi A–E

### Refleksi A
Pada Q1, hak biasa bisa dicabut dari pemilik, tetapi risikonya tetap ada. Jelaskan dari data mengapa “mencabut hak” bukan jalan keluar untuk keluhan K1, dan apa yang menjadi jalan keluarnya.
>> jawaban
---
### Refleksi B
Dengan RLS aktif, apakah penyaring WHERE tenant_id di aplikasi masih perlu ditulis? Jelaskan tugas berbeda yang diemban keduanya, dengan menyebut rencana eksekusi.
>> jawaban
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
>> jawaban
---
### Refleksi E
Jejak audit memuat NIK lama di nilai_lama. Jelaskan ketegangan antara kewajiban merekam pemrosesan (Pasal 31) dan kewajiban menghapus data (Pasal 43), lalu usulkan satu penyelesaian yang dapat Anda pertahankan di hadapan pemeriksa.
>> jawaban

---

## Peta Tiket #1134 ke UU PDP
| Keluhan | Pasal relevan | Kontrol teknis pencegah | Bukti |
|---|---|---|---|

---

## Pernyataan Etika
Seluruh percobaan serangan hanya dijalankan pada kontainer lab11 milik
sendiri di jaringan tertutup. (tanda tangan tiap anggota)

---

## Penggunaan AI dan Verifikasi


---

**merge request :** 