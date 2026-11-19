-- Diminta: membuat view lab4.film_murah yang menampilkan film dengan rental_rate <= 0.99 beserta film_id, title, rental_rate, dan rating tanpa WITH CHECK OPTION.
-- Dipilih: CREATE OR REPLACE VIEW dengan filter WHERE sederhana karena sesuai dengan spesifikasi dasar view fasad.
-- Alternatif: Menggunakan tabel fisik terpisah; tidak dipilih karena membuat duplikasi data dan rentan tidak sinkron dengan tabel master film.

CREATE OR REPLACE VIEW lab4.film_murah AS
SELECT film_id, title, rental_rate, rating
FROM lab4.film
WHERE rental_rate <= 0.99;