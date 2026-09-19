-- Diminta: menghentikan tulis ganda, membuat view fasad untuk mempertahankan akses pembaca lama, lalu menghapus kolom rental_rate dari tabel dasar.
-- Dipilih: menghentikan trigger, mengganti nama tabel dasar menjadi film_base, membuat view lab4.film dengan rental_rate dihitung dari harga_film, lalu menghapus kolom lama setelah view tersedia.
-- Alternatif: menghapus kolom rental_rate secara langsung tanpa view fasad; tidak dipilih karena akan membuat pembaca lama langsung gagal dengan error "column does not exist".

SET search_path TO lab4, public;

-- =========================================================
-- 1. HENTIKAN TULIS GANDA
-- =========================================================
DROP TRIGGER IF EXISTS trg_sync_rental_rate ON lab4.film;

-- =========================================================
-- 2. RENAME TABEL DASAR + BUAT VIEW FASAD (satu transaksi,
--    supaya nama lab4.film tidak pernah hilang bagi sesi lain)
-- =========================================================
BEGIN;

ALTER TABLE lab4.film RENAME TO film_base;

CREATE VIEW lab4.film AS
SELECT
    f.film_id,
    f.title,
    f.description,
    f.release_year,
    f.language_id,
    f.rental_duration,
    h.harga AS rental_rate,
    f.length,
    f.replacement_cost,
    f.rating,
    f.last_update
FROM lab4.film_base f
LEFT JOIN LATERAL (
    SELECT hh.harga
    FROM lab4.harga_film hh
    WHERE hh.film_id = f.film_id
      AND hh.wilayah = 'ID'
      AND hh.berlaku @> CURRENT_DATE
    ORDER BY lower(hh.berlaku) DESC
    LIMIT 1
) h ON TRUE;

COMMIT;

-- =========================================================
-- 3. DROP KOLOM LAMA
-- =========================================================
ALTER TABLE lab4.film_base DROP COLUMN rental_rate;

-- =========================================================
-- 4. VERIFIKASI: pembaca lama tetap bisa baca title & rental_rate
-- =========================================================
SELECT title, rental_rate FROM lab4.film ORDER BY film_id;