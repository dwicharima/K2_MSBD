-- Diminta: jumlah film dan rata-rata tarif per pasangan kategori-rating,
--          subtotal per kategori, dan grand total, dalam satu hasil.
-- Dipilih: GROUP BY ROLLUP(kategori, rating) menghasilkan 3 level:
--          (kategori,rating), (kategori) subtotal, () grand total.
--          GROUPING() dipakai mendeteksi baris subtotal/grand total,
--          lalu CASE mengganti NULL jadi label 'SEMUA'.

SELECT
    CASE WHEN GROUPING(c.name) = 1 THEN 'SEMUA' ELSE c.name END AS kategori,
    CASE WHEN GROUPING(f.rating) = 1 THEN 'SEMUA' ELSE f.rating::text END AS rating,
    COUNT(f.film_id) AS jumlah_film,
    ROUND(AVG(f.rental_rate), 2) AS rata_tarif
FROM film f
JOIN film_category fc ON fc.film_id = f.film_id
JOIN category c ON c.category_id = fc.category_id
GROUP BY ROLLUP (c.name, f.rating)
ORDER BY c.name NULLS LAST, f.rating NULLS LAST;