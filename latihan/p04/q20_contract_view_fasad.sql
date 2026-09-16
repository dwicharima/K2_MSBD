-- Diminta: Hentikan tulis ganda, buat view fasad untuk kompatibilitas aplikasi lama, dan drop kolom lama.
-- Dipilih: Mengubah tabel utama menjadi film_base dan membungkus View lab4.film agar pembaca lama tidak error.
-- Alternatif: Drop kolom langsung tanpa view fasad; tidak dipilih karena langsung merusak query aplikasi lama.

-- 1. Hentikan Trigger Tulis Ganda
DROP TRIGGER IF EXISTS trg_tulis_ganda_harga ON lab4.film;

-- 2. Rename Tabel Dasar (Jalankan jika belum)
-- ALTER TABLE lab4.film RENAME TO film_base;

-- 3. Buat View Fasad Kompatibilitas (Hanya kolom yang benar-benar ada di film_base)
CREATE OR REPLACE VIEW lab4.film AS
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
LEFT JOIN lab4.harga_film h ON h.film_id = f.film_id AND h.wilayah = 'ID';

-- 4. Drop Kolom Lama dari Tabel Dasar dengan CASCADE
ALTER TABLE lab4.film_base DROP COLUMN IF EXISTS rental_rate CASCADE;