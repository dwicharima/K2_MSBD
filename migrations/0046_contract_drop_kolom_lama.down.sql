-- Diminta: Penanganan rollback setelah kolom lama dihapus.
-- Dipilih: ALTER TABLE ADD COLUMN untuk membuat ulang struktur kolom rental_rate.
-- Catatan Penting: Langkah ini tidak dapat mengembalikan nilai historis data lama yang sudah terhapus.

ALTER TABLE lab4.film_base ADD COLUMN IF NOT EXISTS rental_rate numeric(4,2);