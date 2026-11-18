# Praktikum MSBD - Lab 11: Keamanan Basis Data (Database Security)


## Prasyarat (Prerequisites)
* **Docker & Docker Compose** terpasang dan aktif di sistem.
* **Git Bash** (atau terminal berbasis Unix/Linux) untuk eksekusi perintah kontainer.
* Struktur direktori proyek sudah disiapkan sesuai dengan skema modul praktikum `lab11`.

## Cara Menyalakan Kontainer
Menggunakan kontainer Docker (`lab11-db`) yang berjalan di atas *engine* PostgreSQL. 

1. Masuk ke direktori utama proyek lab11:
   cd /c/Semester 3/msbd-2026/lab11
    mkdir -p sql app latihan/p11    
2. docker-compose.lab11.yml memakai jaringan internal: true
docker compose -f docker-compose.lab11.yml up -d
3. Salin dan muat skema setup awal
docker cp sql/lab11_setup.sql lab11-db:/sql/lab11_setup.sql
docker exec -i lab11-db psql -U postgres -d msbd -f /sql/lab11_setup.sql
4. Verifikasi versi database
docker exec -it lab11-db psql -U postgres -d msbd -c "SELECT version();"
5. Bukti jaringan benar-benar tertutup:
docker network inspect lab11_labnet --format '{{.Internal}}'

## Urutan menjalankan Q1–Q30
1. docker exec -i lab11-db psql -U postgres -d msbd < ../latihan/p11/q01_hak_pemilik.sql
2. docker exec -i lab11-db psql -U postgres -d msbd < ../latihan/p11/q02_drop_bukan_hak.sql
3. docker exec -i lab11-db psql -U postgres -d msbd < ../latihan/p11/q03_default_privileges.sql
4. docker exec -i lab11-db psql -U postgres -d msbd < ../latihan/p11/q04_grant_option.sql
5. docker exec -i lab11-db psql -U postgres -d msbd < ../latihan/p11/q05_tabel_peran.sql

## Langkah 4: Menutup Celah Injection (Q12-Q18)

### Prasyarat tambahan
* Q1-Q11 sudah dijalankan berurutan (Q14 bergantung pada RLS dan FORCE dari Q6-Q9).
* Kontainer `lab11-web` memakai `python:3.10-slim` pada jaringan internal tanpa internet,
  sehingga driver `psycopg2` harus dipasang dari berkas wheel yang diunduh lebih dulu.

### Menyiapkan lab11-web (sekali saja, dari direktori lab11)
```
# 1. Unduh wheel di host lewat kontainer sekali pakai (bukan kontainer lab; jaringan bridge biasa)
mkdir -p app/wheels
MSYS_NO_PATHCONV=1 docker run --rm -v "$(pwd -W 2>/dev/null || pwd)/app/wheels:/w" python:3.10-slim \
    pip download psycopg2-binary -d /w
# 2. Pasang di lab11-web tanpa internet
docker exec lab11-web pip install --no-index --find-links=/app/wheels psycopg2-binary
docker exec lab11-web python -c "import psycopg2; print(psycopg2.__version__)"
# 3. Salin skrip aplikasi
cp latihan/p11/rentan.py app/rentan.py
# 4. Cek lab11-web bisa menjangkau basis data (harapan: "Jumlah baris: 100")
docker exec lab11-web python /app/rentan.py --aman --user app_laporan "Pelanggan" | head -3
```

### Urutan menjalankan Q12-Q18
Berkas `.sql` dijalankan di `lab11-db`; perintah `python` dijalankan di `lab11-web`
(perintah lengkapnya ada di komentar tiap berkas qNN).
```
docker exec -i lab11-db psql -U postgres -d msbd < latihan/p11/q12_perilaku_normal.sql
docker exec -it lab11-web python /app/rentan.py "Pelanggan 12"
docker exec -i lab11-db psql -U postgres -d msbd < latihan/p11/q13_sebab_bukan_kutip.sql
docker exec -it lab11-web python /app/rentan.py "zz' OR '1'='1"
docker exec -it lab11-web python /app/rentan.py "zz' OR '1'='1' --"
docker exec -i lab11-db psql -U postgres -d msbd < latihan/p11/q14_batas_hak.sql
docker exec -it lab11-web python /app/rentan.py --user app_laporan "zz' OR '1'='1' --"
docker exec -i lab11-db psql -U postgres -d msbd < latihan/p11/q15_perbaikan.sql
docker exec -it lab11-web python /app/rentan.py --aman "zz' OR '1'='1' --"
docker exec -i lab11-db psql -U postgres -d msbd < latihan/p11/q16_pengenal_daftar_putih.sql
docker exec -it lab11-web python /app/rentan.py --urut kota --arah turun "Pelanggan 12"
docker exec -i lab11-db psql -U postgres -d msbd < latihan/p11/q17_second_order.sql
docker exec -it lab11-web python /app/rentan.py --second-order
docker exec -i lab11-db psql -U postgres -d msbd < latihan/p11/q18_batas_waktu.sql
```
Catatan: `q17` membuat fungsi `laporan_kota_rentan` dan `laporan_kota_aman`; `q18` memasang
`statement_timeout = 5s` pada `app_portal` (setup memuat ulang akan meresetnya). Semua uji tulis
dibungkus transaksi yang di-ROLLBACK.

## Langkah 5: Enkripsi, Hashing, dan Penyamaran (Q19-Q24)

### Prasyarat tambahan
* Q1-Q18 sudah dijalankan (Q23 memakai peran `app_analitik` dari setup; Q24 memakai view dari Q23).
* Ekstensi `pgcrypto` dipasang oleh berkas Q19-Q21 sendiri (`CREATE EXTENSION IF NOT EXISTS pgcrypto`).

### Urutan menjalankan Q19-Q24 (dari direktori lab11)
```
docker exec -i lab11-db psql -U postgres -d msbd < latihan/p11/q19_hash_vs_enkripsi.sql
docker exec -i lab11-db psql -U postgres -d msbd < latihan/p11/q20_biaya_kerja.sql
docker exec -i lab11-db psql -U postgres -d msbd < latihan/p11/q21_enkripsi_kolom.sql
# Q22 butuh dua terminal: perintah sesi 1 ada di komentar atas q22_kunci_bocor.sql
docker exec -i lab11-db psql -U postgres -d msbd < latihan/p11/q22_kunci_bocor.sql
docker exec -i lab11-db psql -U postgres -d msbd < latihan/p11/q23_penyamaran.sql
docker exec -i lab11-db psql -U postgres -d msbd < latihan/p11/q24_identifikasi_ulang.sql
```
Catatan: Q19 memakai tabel TEMP (lab11.akun tidak punya kolom kata sandi); Q21 menambah kolom
`rekening_enc` ke lab11.pelanggan; Q23 mencabut `pg_read_all_data` dari app_analitik dan membuat
view `lab11.v_pelanggan_samar`; Q24 harus dijalankan setelah Q23.
