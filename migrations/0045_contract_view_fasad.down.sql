-- Diminta: mengembalikan struktur tabel ke kondisi sebelum dibuatnya view fasad.
-- Dipilih: DROP VIEW lalu RENAME kembali film_base menjadi film, dan pasang ulang trigger tulis-ganda agar kondisi benar-benar identik dengan sebelum 0045 dijalankan.
-- Alternatif: hanya mengembalikan nama tabel tanpa memasang ulang trigger; tidak dipilih karena rollback yang tidak simetris bisa membingungkan migrasi berikutnya.

DROP VIEW IF EXISTS lab4.film;
ALTER TABLE lab4.film_base RENAME TO film;

CREATE OR REPLACE FUNCTION lab4.sync_rental_rate_to_harga_film()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO lab4.harga_film (film_id, wilayah, harga, berlaku)
    VALUES (NEW.film_id, 'ID', NEW.rental_rate, daterange(CURRENT_DATE, NULL, '[)'))
    ON CONFLICT DO NOTHING;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_sync_rental_rate
AFTER UPDATE OF rental_rate ON lab4.film
FOR EACH ROW
EXECUTE FUNCTION lab4.sync_rental_rate_to_harga_film();