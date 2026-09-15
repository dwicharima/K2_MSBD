-- Diminta: membuat ulang view lab4.film_murah dengan WITH CASCADED CHECK OPTION, mengulangi penyisipan data dengan rental_rate = 4.99, dan menyalin pesan galat secara utuh.
-- Dipilih: Menggunakan CREATE OR REPLACE VIEW ditambah klausa WITH CASCADED CHECK OPTION agar setiap data yang dimasukkan wajib lolos dari filter WHERE view.
-- Alternatif: Menggunakan WITH LOCAL CHECK OPTION; tidak dipilih karena untuk view tunggal tanpa view bertingkat, cascaded lebih aman untuk memastikan tidak ada celah aturan filter.

CREATE OR REPLACE VIEW lab4.film_murah AS
SELECT film_id, title, rental_rate, rating
FROM lab4.film
WHERE rental_rate <= 0.99
WITH CASCADED CHECK OPTION;

INSERT INTO lab4.film_murah (title, rental_rate, rating)
VALUES ('Film Ditolak Q3', 4.99, 'PG');