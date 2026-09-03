-- =========================================================
-- Langkah 6 — Seed Data Idempoten
-- File: latihan/p02/seeds/01_mahasiswa.sql
--
-- Seed ini mengisi data dasar mahasiswa yang dapat digunakan
-- untuk pengujian tim, pendaftaran, dan keanggotaan tim.
--
-- Idempoten karena target konflik (nim) adalah PRIMARY KEY
-- pada tabel mahasiswa, sehingga menjalankan skrip ini
-- berkali-kali tidak akan pernah menghasilkan baris duplikat --
-- baris dengan nim yang sudah ada akan di-UPDATE, bukan
-- di-INSERT ulang.
-- =========================================================

INSERT INTO mahasiswa (nim, nama_mahasiswa, program_studi, angkatan, nomor_telepon) VALUES
('231402001', 'Ahmad Fauzan',    'Teknologi Informasi', 2023, '081234560001'),
('231402002', 'Siti Aisyah',     'Teknologi Informasi', 2023, '081234560002'),
('231402003', 'Budi Santoso',    'Ilmu Komputer',       2023, '081234560003'),
('231402004', 'Dewi Lestari',    'Ilmu Komputer',       2023, '081234560004'),
('231402005', 'Rizky Ramadhan',  'Sistem Informasi',    2023, '081234560005')
ON CONFLICT (nim)
DO UPDATE SET
    nama_mahasiswa = EXCLUDED.nama_mahasiswa,
    program_studi  = EXCLUDED.program_studi,
    angkatan       = EXCLUDED.angkatan,
    nomor_telepon  = EXCLUDED.nomor_telepon;
