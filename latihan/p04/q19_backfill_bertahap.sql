-- Diminta: Melakukan backfill data rental_rate ke harga_film dalam potongan 1000 film untuk seluruh rentang, lalu menjalankan verifikasi yang harus menghasilkan nol.
-- Dipilih: Menggunakan loop dengan batch 1000 dan NOT EXISTS agar data yang sudah tersalin tidak dimasukkan kembali serta seluruh rentang film dapat diproses.
-- Alternatif: Menggunakan satu INSERT besar untuk seluruh film; tidak dipilih karena tugas meminta backfill bertahap dalam potongan 1000 film.

SET search_path TO lab4, public;

-- =========================================================
-- BACKFILL BERTAHAP 1000 FILM
-- =========================================================

DO $$
DECLARE
    v_start integer := 1;
    v_end integer;
    v_max integer;
BEGIN
    SELECT COALESCE(MAX(film_id), 0)
    INTO v_max
    FROM lab4.film;

    WHILE v_start <= v_max LOOP
        v_end := v_start + 999;

        INSERT INTO lab4.harga_film
            (film_id, wilayah, harga, berlaku)
        SELECT
            f.film_id,
            'ID',
            f.rental_rate,
            daterange('2026-01-01', NULL, '[)')
        FROM lab4.film f
        WHERE f.film_id BETWEEN v_start AND v_end
          AND NOT EXISTS (
              SELECT 1
              FROM lab4.harga_film h
              WHERE h.film_id = f.film_id
                AND h.wilayah = 'ID'
          );

        RAISE NOTICE 'Backfill film % sampai % selesai',
            v_start, v_end;

        v_start := v_start + 1000;
    END LOOP;
END $$;

-- =========================================================
-- VERIFIKASI
-- Target: 0
-- =========================================================

SELECT count(*) AS sisa_belum_terisi
FROM lab4.film f
WHERE NOT EXISTS (
    SELECT 1
    FROM lab4.harga_film h
    WHERE h.film_id = f.film_id
      AND h.wilayah = 'ID'
);