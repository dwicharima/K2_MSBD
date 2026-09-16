-- Diminta: Menghentikan tulis ganda, membuat view fasad untuk mempertahankan akses pembaca lama, lalu menghapus kolom rental_rate dari tabel dasar.
-- Dipilih: Menghentikan trigger, mengganti nama tabel dasar menjadi film_base, membuat view lab4.film dengan rental_rate dari harga_film, lalu menghapus kolom lama setelah view tersedia.
-- Alternatif: Menghapus kolom rental_rate secara langsung; tidak dipilih karena akan menyebabkan pembaca lama gagal sebelum view fasad tersedia.

SET search_path TO lab4, public;

-- =========================================================
-- 1. HENTIKAN TULIS GANDA
-- =========================================================

DROP TRIGGER IF EXISTS trg_sync_rental_rate
ON lab4.film;

-- =========================================================
-- 2. RENAME TABEL DASAR
-- =========================================================

ALTER TABLE lab4.film
RENAME TO film_base;

-- =========================================================
-- 3. BUAT VIEW FASAD
-- =========================================================

CREATE OR REPLACE VIEW lab4.film AS
SELECT
    f.film_id,
    f.title,
    f.description,
    f.release_year,
    f.language_id,
    f.original_language_id,
    f.rental_duration,
    h.harga AS rental_rate,
    f.length,
    f.replacement_cost,
    f.rating,
    f.last_update,
    f.special_features,
    f.fulltext,
    f.deleted_at
FROM lab4.film_base f
LEFT JOIN lab4.harga_film h
    ON h.film_id = f.film_id
   AND h.wilayah = 'ID';

-- =========================================================
-- 4. DROP KOLOM LAMA
-- =========================================================

ALTER TABLE lab4.film_base
DROP COLUMN rental_rate;