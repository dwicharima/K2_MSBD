-- Diminta: melakukan backfill lab4.harga_film dari lab4.film.rental_rate dalam potongan 1000 film, lalu menjalankan verifikasi yang harus menghasilkan nol.
-- Dipilih: DO-block dengan loop batch 1000 dan NOT EXISTS yang memeriksa keberadaan periode 'ID' yang SEDANG BERLAKU (berlaku @> CURRENT_DATE), bukan sekadar "pernah ada baris ID", supaya film dengan riwayat harga yang sudah kedaluwarsa tetap ikut di-backfill dengan harga terkininya.
-- Alternatif: NOT EXISTS tanpa syarat periode aktif; tidak dipilih karena sempat terbukti bug -- film dengan entri harga lama yang sudah kedaluwarsa (seperti demo Q17) dianggap "sudah lengkap" padahal tidak punya harga yang berlaku hari ini, menyebabkan rental_rate menjadi NULL setelah kolom lama di-drop di Q20.

SET search_path = lab4, public;

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
            daterange(CURRENT_DATE, NULL, '[)')
        FROM lab4.film f
        WHERE f.film_id BETWEEN v_start AND v_end
          AND NOT EXISTS (
              SELECT 1
              FROM lab4.harga_film h
              WHERE h.film_id = f.film_id
                AND h.wilayah = 'ID'
                AND h.berlaku @> CURRENT_DATE
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
      AND h.berlaku @> CURRENT_DATE
);