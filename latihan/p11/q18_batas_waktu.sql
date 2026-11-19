-- Diminta: memasang ALTER ROLE app_portal SET statement_timeout = '5s'; menjelaskan, tanpa
--          menjalankan serangan penundaan pada sistem lain, bagaimana batas waktu membuat
--          percobaan berbasis pg_sleep menjadi berisik di log; dan mengutip SQLSTATE bila
--          sebuah query melewati batas.
-- Dipilih: batas waktu per peran (ALTER ROLE ... SET), karena melekat pada peran aplikasi
--          dan berlaku otomatis di setiap koneksi barunya tanpa mengubah kode aplikasi.
--          Pengujian hanya memakai pg_sleep(2) dan pg_sleep(6) di kontainer lab11 sendiri.
-- Alternatif: statement_timeout global di postgresql.conf; tidak dipilih karena ikut membatasi
--             peran lain (laporan, migrasi) yang sah membutuhkan query lama.

-- ===== 1. Pasang batas waktu (sebagai postgres) =====
ALTER ROLE app_portal SET statement_timeout = '5s';

-- ===== 2. Bukti terpasang =====
SELECT rolname, rolconfig FROM pg_roles WHERE rolname = 'app_portal';

-- ===== 3. Uji dari sesi BARU sebagai app_portal (ALTER ROLE ... SET hanya berlaku pada
--          koneksi baru; SET ROLE tidak cukup). \c membuka koneksi baru. =====
\c msbd app_portal
\set VERBOSITY verbose
SELECT current_user AS peran_aktif;
SHOW statement_timeout;
SELECT pg_sleep(2) AS dibawah_batas;      -- lolos (2 detik < 5 detik)
SELECT pg_sleep(6) AS melewati_batas;     -- dibatalkan server setelah 5 detik
\set VERBOSITY default

-- ===== 4. Kembali sebagai postgres =====
\c msbd postgres

-- ===== 5. Jejak di log server (jalankan dari terminal host, bukan dari psql): =====
--   docker logs --tail 20 lab11-db 2>&1 | grep -B1 -A2 "statement timeout"
-- Contoh isi yang diharapkan:
--   ERROR:  canceling statement due to statement timeout
--   STATEMENT:  SELECT pg_sleep(6) AS melewati_batas;
--
-- Mengapa berisik: serangan time-based blind injection bertanya "benar atau salah?" lewat
-- lamanya jawaban (mis. tidur N detik bila tebakan benar). Dengan batas 5 detik:
--   (a) setiap tebakan yang tidur lebih dari batas MENGHASILKAN GALAT 57014 dan satu baris
--       ERROR + STATEMENT di log; ratusan tebakan berarti ratusan baris galat berpola sama;
--   (b) penyerang terpaksa memakai jeda pendek (< 5 detik) sehingga satu bit informasi makin
--       mahal waktunya, dan pola pg_sleep berulang dari satu peran mudah dikenali;
--   (c) koneksi tidak tersandera lama, jadi serangan sulit dipakai untuk menghabiskan kolam.
-- Batas waktu BUKAN penutup celah: injection tetap terjadi. Ia membatasi dampak dan menambah
-- sinyal untuk pemantauan; penutup sebabnya tetap query berparameter (Q15).

-- ===== 6. Pembersihan (opsional): kembalikan seperti semula bila kelompok menghendaki =====
--   ALTER ROLE app_portal RESET statement_timeout;
-- (lab11_setup.sql juga sudah melakukan RESET ini setiap kali skema dimuat ulang.)
