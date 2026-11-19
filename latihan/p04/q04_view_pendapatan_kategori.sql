-- Diminta: membuat view lab4.pendapatan_kategori yang menggunakan GROUP BY, mencoba menyisipkan data melaluinya, lalu menjelaskan alasan view tersebut tidak auto-updatable.
-- Dipilih: Membuat view dengan fungsi agregat count dan avg beserta GROUP BY rating untuk melihat pembatasan mutasi data pada view non-updatable.
-- Alternatif: Menggunakan view biasa tanpa agregasi; tidak dipilih karena tidak sesuai dengan soal yang menguji batasan view berbasis agregasi.

CREATE OR REPLACE VIEW lab4.pendapatan_kategori AS
SELECT rating, count(*) AS total_film, avg(rental_rate) AS rata_rental
FROM lab4.film
GROUP BY rating;

INSERT INTO lab4.pendapatan_kategori (rating, total_film, rata_rental)
VALUES ('NC-17', 10, 3.50);