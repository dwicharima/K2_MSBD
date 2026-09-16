-- Diminta: membuat struktur harga_film dan trigger tulis ganda agar perubahan rental_rate pada lab4.film tercermin pada struktur harga baru.
-- Dipilih: AFTER UPDATE OF rental_rate dengan WHEN OLD.rental_rate IS DISTINCT FROM NEW.rental_rate karena hanya perubahan harga yang perlu disalin ke harga_film.
-- Alternatif: melakukan sinkronisasi secara manual setelah UPDATE; tidak dipilih karena mudah terlupa dan tidak menjamin data baru langsung mengikuti perubahan rental_rate.

SET search_path TO lab4, public;

-- Struktur baru
CREATE TABLE IF NOT EXISTS lab4.harga_film (
    harga_film_id bigserial PRIMARY KEY,
    film_id integer NOT NULL REFERENCES lab4.film (film_id),
    wilayah text NOT NULL,
    harga numeric(5,2) NOT NULL CHECK (harga >= 0),
    berlaku daterange NOT NULL,
    EXCLUDE USING gist (
        film_id WITH =,
        wilayah WITH =,
        berlaku WITH &&
    )
);

-- Function untuk tulis ganda
CREATE OR REPLACE FUNCTION lab4.sync_rental_rate_to_harga_film()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO lab4.harga_film
        (film_id, wilayah, harga, berlaku)
    VALUES
        (NEW.film_id, 'default', NEW.rental_rate, daterange(CURRENT_DATE, NULL, '[)'));

    RETURN NEW;
END;
$$;

-- Trigger tulis ganda
DROP TRIGGER IF EXISTS trg_sync_rental_rate ON lab4.film;

CREATE TRIGGER trg_sync_rental_rate
AFTER UPDATE OF rental_rate ON lab4.film
FOR EACH ROW
WHEN (OLD.rental_rate IS DISTINCT FROM NEW.rental_rate)
EXECUTE FUNCTION lab4.sync_rental_rate_to_harga_film();