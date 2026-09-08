# Latihan Pertemuan 3 - SQL Lanjutan I

## Tujuan Latihan
Praktik dan eksplorasi lanjutan konsep SQL tingkat lanjut menggunakan PostgreSQL 17 pada basis data sampel Pagila, mencakup penggunaan subquery, logika tiga nilai (*Three-Valued Logic*), dan optimasi kueri tanpa fungsi *window*.

## Prasyarat
- Docker aktif dan kontainer layanan database berjalan
- PostgreSQL 17
- Basis data Pagila sudah terpasang di dalam kontainer

## Menjalankan Setup
docker compose exec -T db psql -U msbd -d pagila \
  -f /dev/stdin < latihan/p03/q00_setup.sql

## Menjalankan Jawaban
docker compose exec -T db psql -U msbd -d pagila -f /dev/stdin < latihan/p03/q01_tarif_di_atas_rata.sql
docker compose exec -T db psql -U msbd -d pagila -f /dev/stdin < latihan/p03/q02_film_durasi_maksimal.sql
docker compose exec -T db psql -U msbd -d pagila -f /dev/stdin < latihan/p03/q03_pelanggan_multi_pembayaran.sql
docker compose exec -T db psql -U msbd -d pagila -f /dev/stdin < latihan/p03/q04_film_tidak_pernah_disewa.sql
docker compose exec -T db psql -U msbd -d pagila -f /dev/stdin < latihan/p03/q05_tarif_tertinggi_per_toko.sql


## Catatan Q9



## Anggota 

- Rasyd Arija Azron Ritonga - 251402020
- Fakhry Adrian Daulay - 251402053
- Dwi Charima Husni - 251402088 - Project Manager
- Agnes Natalia Br Siregar - 251402108
- Abdullah Zufar Aulia Nasution - 251402111
