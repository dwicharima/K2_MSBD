-- Diminta: Membuat fase expand dengan struktur baru dan trigger tulis ganda agar perubahan rental_rate pada bentuk lama tercermin pada bentuk baru.
-- Dipilih: Membuat tabel harga_film dan trigger AFTER UPDATE OF rental_rate dengan WHEN IS DISTINCT FROM agar perubahan harga pada bentuk lama disinkronkan ke bentuk baru.
-- Alternatif: Melakukan backfill dan membuat view pada tahap ini; tidak dipilih karena tugas menetapkan enam tahap expand–contract secara berurutan.

SET search_path TO lab4, public;

-- =========================================================
-- 1. BUAT STRUKTUR BARU
-- =========================================================

CREATE TABLE IF NOT EXISTS lab4.harga_film (
    harga_film_id bigserial PRIMARY KEY,
    film_id integer NOT NULL REFERENCES lab4.film (film_id),
    wilayah text NOT NULL,
    harga numeric(5,2) NOT NULL CHECK (harga >= 0),
    berlaku daterange NOT NULL,
    CONSTRAINT exclude_harga_film
        EXCLUDE USING gist (
            film_id WITH =,
            wilayah WITH =,
            berlaku WITH &&
        )
);

-- =========================================================
-- 2. PASANG TULIS GANDA
-- =========================================================

CREATE OR REPLACE FUNCTION lab4.sync_rental_rate_to_harga_film()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE lab4.harga_film
    SET harga = NEW.rental_rate
    WHERE film_id = NEW.film_id
      AND wilayah = 'ID'
      AND upper_inf(berlaku);

    IF NOT FOUND THEN
        INSERT INTO lab4.harga_film
            (film_id, wilayah, harga, berlaku)
        VALUES
            (
                NEW.film_id,
                'ID',
                NEW.rental_rate,
                daterange(CURRENT_DATE, NULL, '[)')
            );
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_rental_rate
ON lab4.film;

CREATE TRIGGER trg_sync_rental_rate
AFTER UPDATE OF rental_rate ON lab4.film
FOR EACH ROW
WHEN (OLD.rental_rate IS DISTINCT FROM NEW.rental_rate)
EXECUTE FUNCTION lab4.sync_rental_rate_to_harga_film();