-- Diminta: Membuat tabel ulasan dengan foreign key ke film dan menguji NO ACTION, CASCADE, serta SET NULL.
-- Dipilih: Menggunakan tiga tabel ulasan dengan aksi referensial berbeda agar setiap perilaku penghapusan dapat diuji secara terpisah.
-- Alternatif: Menggunakan satu tabel ulasan lalu mengubah constraint berkali-kali; tidak dipilih karena lebih sulit membandingkan hasil setiap aksi.

SET search_path = lab4, public;

-- =========================================================
-- 1. NO ACTION
--=========================================================

DROP TABLE IF EXISTS lab4.ulasan_no_action CASCADE;

CREATE TABLE lab4.ulasan_no_action (
    ulasan_id bigserial PRIMARY KEY,
    film_id integer NOT NULL,
    isi_ulasan text,
    CONSTRAINT fk_ulasan_film_no_action
        FOREIGN KEY (film_id)
        REFERENCES lab4.film (film_id)
        ON DELETE NO ACTION
);

INSERT INTO lab4.ulasan_no_action (film_id, isi_ulasan)
VALUES (1, 'Film bagus');

-- Coba hapus film induk
DELETE FROM lab4.film
WHERE film_id = 1;
-- =========================================================
-- 2. CASCADE
-- =========================================================

DROP TABLE IF EXISTS lab4.ulasan_cascade CASCADE;

CREATE TABLE lab4.ulasan_cascade (
    ulasan_id bigserial PRIMARY KEY,
    film_id integer NOT NULL,
    isi_ulasan text,
    CONSTRAINT fk_ulasan_film_cascade
        FOREIGN KEY (film_id)
        REFERENCES lab4.film (film_id)
        ON DELETE CASCADE
);

INSERT INTO lab4.ulasan_cascade (film_id, isi_ulasan)
VALUES (2, 'Film sangat menarik');

SELECT *
FROM lab4.ulasan_cascade
WHERE film_id = 2;

DELETE FROM lab4.film
WHERE film_id = 2;

SELECT *
FROM lab4.ulasan_cascade
WHERE film_id = 2;

-- =========================================================
-- 3. SET NULL
-- =========================================================

DROP TABLE IF EXISTS lab4.ulasan_set_null CASCADE;

CREATE TABLE lab4.ulasan_set_null (
    ulasan_id bigserial PRIMARY KEY,
    film_id integer,
    isi_ulasan text,
    CONSTRAINT fk_ulasan_film_set_null
        FOREIGN KEY (film_id)
        REFERENCES lab4.film (film_id)
        ON DELETE SET NULL
);

INSERT INTO lab4.ulasan_set_null (film_id, isi_ulasan)
VALUES (3, 'Film cukup bagus');

SELECT *
FROM lab4.ulasan_set_null
WHERE film_id = 3;

DELETE FROM lab4.film
WHERE film_id = 3;

SELECT *
FROM lab4.ulasan_set_null
WHERE ulasan_id = 1;
