-- Diminta: Mengalihkan pembaca lama ke View Fasad agar aplikasi tidak error saat kolom lama dihapus.
-- Dipilih: Rename tabel film menjadi film_base, lalu buat View lab4.film yang me-JOIN tabel baru.
-- Alternatif: Menghapus kolom langsung; tidak dipilih karena akan merusak query pada aplikasi versi lama.

DROP TRIGGER IF EXISTS trg_tulis_ganda_harga ON lab4.film;

ALTER TABLE lab4.film RENAME TO film_base;

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
LEFT JOIN lab4.harga_film h ON h.film_id = f.film_id AND h.wilayah = 'ID';