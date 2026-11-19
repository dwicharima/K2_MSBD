-- Diminta: Menghapus kolom lama rental_rate dari tabel dasar setelah semua aplikasi terhubung ke skema baru.
-- Dipilih: ALTER TABLE DROP COLUMN pada tabel dasar film_base.
-- Alternatif: Membiarkan kolom kosong; tidak dipilih karena menyisakan data sampah (dead column).

ALTER TABLE lab4.film_base DROP COLUMN IF EXISTS rental_rate;