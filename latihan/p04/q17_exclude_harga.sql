-- Diminta: membuat tabel harga film dengan constraint EXCLUDE sehingga periode harga film dan wilayah yang sama tidak boleh tumpang tindih.
-- Dipilih: EXCLUDE USING gist pada film_id, wilayah, dan berlaku dengan btree_gist karena dapat mencegah periode harga yang tumpang tindih untuk film dan wilayah yang sama.
-- Alternatif: menggunakan trigger untuk memeriksa tumpang tindih periode; tidak dipilih karena EXCLUDE constraint lebih sederhana dan langsung didukung PostgreSQL.

SET search_path TO lab4, public;

CREATE EXTENSION IF NOT EXISTS btree_gist;

DROP TABLE IF EXISTS lab4.harga_film;

CREATE TABLE lab4.harga_film (
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

-- INSERT diterima
INSERT INTO lab4.harga_film
    (film_id, wilayah, harga, berlaku)
VALUES
    (1, 'ID', 50.00, '[2026-01-01,2026-04-01)');

-- Melihat data
SELECT * FROM lab4.harga_film;

-- INSERT ditolak karena periode tumpang tindih
INSERT INTO lab4.harga_film
    (film_id, wilayah, harga, berlaku)
VALUES
    (1, 'ID', 60.00, '[2026-03-01,2026-06-01)');