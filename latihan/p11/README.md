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