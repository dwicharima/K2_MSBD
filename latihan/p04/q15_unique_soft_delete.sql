ALTER TABLE lab4.film ADD COLUMN deleted_at timestamptz;
ALTER TABLE lab4.film ADD CONSTRAINT film_judul_unik UNIQUE (title);

-- Buktikan masalahnya
UPDATE lab4.film SET deleted_at = now() WHERE title = 'Film A';
INSERT INTO lab4.film (title, rental_rate, rating) VALUES ('Film A', 3.99, 'PG');
-- ERROR: duplicate key value violates unique constraint "film_judul_unik"
-- (padahal 'Film A' yang lama sudah soft-delete, seharusnya boleh daftar ulang)

-- Setelah bukti masalah dicatat, ganti dengan unique index parsial
ALTER TABLE lab4.film DROP CONSTRAINT film_judul_unik;

CREATE UNIQUE INDEX ux_film_judul_aktif
ON lab4.film (title) WHERE deleted_at IS NULL;

-- Ulangi insert yang sama -> sekarang berhasil, karena baris lama sudah "tidak aktif"
INSERT INTO lab4.film (title, rental_rate, rating) VALUES ('Film A', 3.99, 'PG');