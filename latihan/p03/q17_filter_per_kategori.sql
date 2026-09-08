SELECT
    c.name AS kategori,
    COUNT(f.film_id) AS jumlah_total,
    COUNT(CASE WHEN f.rating = 'G' THEN f.film_id END) AS jumlah_g,
    COUNT(CASE WHEN f.rating = 'PG-13' THEN f.film_id END) AS jumlah_pg13,
    ROUND(AVG(CASE WHEN f.length > 90 THEN f.length END), 2) AS rata_durasi_lebih_90
FROM film f
JOIN film_category fc ON fc.film_id = f.film_id
JOIN category c ON c.category_id = fc.category_id
GROUP BY c.name
ORDER BY c.name;