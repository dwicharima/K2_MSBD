# Laporan Latihan - Pertemuan 1 - Kelompok 2 - Manajemen Sistem Basis Data

**Anggota Kelompok :**
- Rasyd Arija Azron Ritonga (251402020)
- Fakhry Adrian Daulay (251402053)
- Dwi Charima Husni (251402088) - Project Manager
- Agnes Natalia Br Siregar (251402108)
- Abdullah Zufar Aulia Nasution (251402111)

---

 ### Domain: Manajemen Kompetisi Antar-Mahasiswa. 

---

### Cara menjalankan Docker Compose

- Buka Terminal di folder project.
- Jalankan menggunakan perintah docker compose up -d
- Cek status menggunakan perintah docker compose ps

---

### Cara Menjalankan Migration

- Jalankan migration menggunakan docker compose run --rm flyway migrate
- Cek status migration menggunakan docker compose run --rm flyway info

---

### Cara Menjalankan Seed Data
Untuk menjalankan seed data, gunakan perintah berikut untuk memasukkan data awal dari file 01_mahasiswa.sql ke database proyek_dev:
docker compose exec -T postgres psql -U msbd -d proyek_dev < latihan/p02/seeds/01_mahasiswa.sql

---