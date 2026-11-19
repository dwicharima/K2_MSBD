-- Diminta: Membuat tabel baru lab4.harga_film untuk menampung skema harga per wilayah.
-- Dipilih: Menggunakan EXCLUDE constraint dengan ekstensi btree_gist untuk mencegah rentang tanggal tumpang tindih.
-- Alternatif: Menggunakan trigger validasi manual; tidak dipilih karena rawan race condition pada eksekusi konkuren.

CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE TABLE IF NOT EXISTS lab4.harga_film (
    harga_film_id bigserial PRIMARY KEY,
    film_id integer NOT NULL REFERENCES lab4.film (film_id),
    wilayah text NOT NULL,
    harga numeric(5,2) NOT NULL CHECK (harga >= 0),
    berlaku daterange NOT NULL,
    EXCLUDE USING gist (film_id WITH =, wilayah WITH =, berlaku WITH &&)
);