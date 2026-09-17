-- Diminta: mengalihkan pembaca lama ke view fasad agar aplikasi tidak error saat kolom lama dihapus.
-- Dipilih: rename tabel film menjadi film_base, lalu buat VIEW lab4.film yang mengambil rental_rate dari harga_film periode yang sedang berlaku (LATERAL + berlaku @> CURRENT_DATE), dibungkus satu transaksi bersama rename supaya nama lab4.film tidak pernah hilang.
-- Alternatif: menghapus kolom langsung tanpa view fasad; tidak dipilih karena akan merusak query pada aplikasi versi lama.

DROP TRIGGER IF EXISTS trg_sync_rental_rate ON lab4.film;

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