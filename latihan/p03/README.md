# Latihan Pertemuan 3 - SQL Lanjutan I

## Tujuan Latihan
Latihan ini dilakukan dengan menggunakan basis data Pagila di PostgreSQL 17. Dalam latihan ini, kami mengerjakan 20 query SQL lanjutan dan satu laporan analitik terpadu (R1). Materi yang digunakan cukup beragam, mulai dari subquery, CTE dan recursive CTE, window function, agregasi lanjutan, hingga pengolahan data JSONB. Selain menghasilkan output yang benar, kami juga belajar menentukan bentuk dan metode query yang paling sesuai untuk menyelesaikan setiap permasalahan.

## Prasyarat
- Docker aktif dan kontainer layanan database berjalan
- PostgreSQL 17
- Basis data Pagila sudah terpasang di dalam kontainer

## Menjalankan Setup
Sebelum menjalankan seluruh query, terlebih dahulu dilakukan setup untuk menyiapkan data dan kondisi yang dibutuhkan dalam pengerjaan tugas. File setup dijalankan melalui Git Bash atau terminal Linux dan diteruskan ke PostgreSQL yang berjalan di dalam container Docker.

docker compose exec -T postgres psql -U msbd -d pagila \
  -f /dev/stdin < latihan/p03/q00_setup.sql

Catatan: Perintah dijalankan menggunakan Git Bash atau terminal Linux. File q00_setup.sql terlebih dahulu dijalankan untuk menyiapkan data tambahan yang dibutuhkan oleh beberapa query berikutnya. Konfigurasi environment kelompok kami menggunakan service PostgreSQL postgres dan user msbd, sehingga perintah disesuaikan dengan konfigurasi tersebut.

## Menjalankan Jawaban
Setelah proses setup selesai, setiap file jawaban dapat dijalankan melalui Git Bash atau terminal Linux dengan meneruskan isi file SQL ke PostgreSQL yang berjalan di dalam container Docker. Berikut contoh perintah untuk menjalankan Q1:

docker compose exec -T postgres psql -U msbd -d pagila \
  -f /dev/stdin < latihan/p03/q01_tarif_di_atas_rata.sql

Ganti nama file sesuai query yang ingin dijalankan, mulai dari Q1–Q20 hingga R1. Q1–Q5 membahas subquery, Q6–Q9 CTE dan recursive CTE, Q10–Q15 window function, Q16–Q18 agregasi lanjutan, dan Q19–Q20 JSONB. q00_setup.sql harus dijalankan terlebih dahulu karena Q6–Q9 membutuhkan tabel pegawai, sedangkan Q19–Q20 membutuhkan tabel notifikasi.

## Catatan Q9
Pada Q9, relasi atasan sementara diubah dengan 

```sql
UPDATE pegawai SET atasan_id = 6 WHERE pegawai_id = 1 
```

Untuk membuat kondisi siklus dan menguji apakah query rekursif dapat menangani siklus tersebut dengan aman. Setelah pengujian selesai, data dikembalikan ke kondisi semula dengan mengatur kembali atasan_id menjadi NULL agar perubahan sementara tidak memengaruhi query atau data selanjutnya.

## Pembagian Tugas

- Agnes: Q1-Q5 (Subquery), Refleksi A, setup q00
- Abdullah: Q6-Q9 (CTE & Recursive CTE), Refleksi B
- Fakhry: Q10-Q13 (Window Function), Refleksi C
- Rasyd: Q14–Q15 (Window Function), Q16–Q17 (Agregasi Lanjutan), Refleksi C
- Dwi: Q18-Q20 (Agregasi & JSONB), R1, Refleksi D-E

## Anggota 

- Rasyd Arija Azron Ritonga - 251402020
- Fakhry Adrian Daulay - 251402053
- Dwi Charima Husni - 251402088 - Project Manager
- Agnes Natalia Br Siregar - 251402108
- Abdullah Zufar Aulia Nasution - 251402111
