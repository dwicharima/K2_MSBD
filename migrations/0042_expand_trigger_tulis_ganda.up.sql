-- Diminta: Mengaktifkan sinkronisasi otomatis dari kolom lama ke tabel baru saat ada perubahan data.
-- Dipilih: AFTER INSERT OR UPDATE OF rental_rate ON lab4.film untuk menjaga konsistensi data secara real-time.
-- Alternatif: Sinkronisasi di kode aplikasi; tidak dipilih karena berisiko jika ada akses langsung via query/SQL.

CREATE OR REPLACE FUNCTION lab4.sync_tulis_ganda_harga()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO lab4.harga_film (film_id, wilayah, harga, berlaku)
    VALUES (NEW.film_id, 'ID', NEW.rental_rate, daterange('2026-01-01', NULL))
    ON CONFLICT DO NOTHING;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_tulis_ganda_harga ON lab4.film;

CREATE TRIGGER trg_tulis_ganda_harga
AFTER INSERT OR UPDATE OF rental_rate ON lab4.film
FOR EACH ROW
EXECUTE FUNCTION lab4.sync_tulis_ganda_harga();