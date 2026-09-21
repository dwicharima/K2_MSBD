-- Diminta: menguji penambahan status 'EXPIRED' pada ENUM lab5.rental_status dan perilakunya.
-- Dipilih: penggunaan ALTER TYPE ... ADD VALUE untuk memperluas definisi ENUM secara aman.
-- Alternatif: mengubah kolom menjadi VARCHAR; tidak dipilih karena menghilangkan validasi ketat tingkat basis data.

-- 1. Coba set status ke 'EXPIRED' sebelum diperbarui
UPDATE lab5.rental_tx 
SET status = 'EXPIRED' 
WHERE rental_id = 1;

-- Galat yang dihasilkan:
-- ERROR:  invalid input value for enum lab5.rental_status: "EXPIRED"
-- SQLSTATE: 22P02

-- 2. Tambahkan nilai 'EXPIRED' ke dalam ENUM
ALTER TYPE lab5.rental_status ADD VALUE 'EXPIRED';

-- 3. Ulangi percobaan pembaruan status
UPDATE lab5.rental_tx 
SET status = 'EXPIRED' 
WHERE rental_id = 1;

-- Hasil:
-- UPDATE 1 (Berhasil diperbarui tanpa galat)