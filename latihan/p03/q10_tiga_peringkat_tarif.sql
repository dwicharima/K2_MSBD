-- Diminta: menampilkan judul, kategori, tarif sewa, serta ROW_NUMBER, RANK,
-- DENSE_RANK untuk setiap film berdasarkan tarif di dalam kategorinya.
--
-- Dipilih: satu klausa WINDOW w AS (...) digunakan tiga kali agar definisi
-- PARTITION BY dan ORDER BY tidak perlu ditulis berulang.
--
-- Alternatif: menulis PARTITION BY dan ORDER BY pada setiap OVER; tidak dipilih
-- karena query menjadi lebih panjang dan definisi window mudah tidak konsisten.

SELECT
    f.title,
    c.name AS category,
    f.rental_rate,
    ROW_NUMBER() OVER w AS row_number,
    RANK() OVER w AS rank,
    DENSE_RANK() OVER w AS dense_rank
FROM film f
JOIN film_category fc
    ON fc.film_id = f.film_id
JOIN category c
    ON c.category_id = fc.category_id
WINDOW w AS (
    PARTITION BY c.category_id
    ORDER BY f.rental_rate DESC
)
ORDER BY c.name, f.rental_rate DESC, f.title;