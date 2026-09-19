-- Diminta: menampilkan tiga film dengan tarif sewa tertinggi pada setiap kategori.
--
-- Dipilih: window function dihitung di dalam CTE, kemudian hasilnya disaring
-- pada query luar agar hanya peringkat 1 sampai 3 yang ditampilkan.
--
-- Alternatif: menggunakan subquery biasa untuk mencari tarif maksimum;
-- tidak dipilih karena lebih sulit mendapatkan tiga film teratas untuk setiap kategori.

WITH ranked_films AS (
    SELECT
        f.title,
        c.name AS category,
        f.rental_rate,
        ROW_NUMBER() OVER (
            PARTITION BY c.category_id
            ORDER BY f.rental_rate DESC
        ) AS rn
    FROM film f
    JOIN film_category fc
        ON fc.film_id = f.film_id
    JOIN category c
        ON c.category_id = fc.category_id
)
SELECT
    title,
    category,
    rental_rate
FROM ranked_films
WHERE rn <= 3
ORDER BY category, rn, title;