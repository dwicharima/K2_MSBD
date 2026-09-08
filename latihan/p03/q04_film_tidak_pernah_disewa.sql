-- Diminta: mencari judul film yang tidak pernah disewa (menggunakan NOT IN dan NOT EXISTS).
-- Dipilih: NOT EXISTS karena lebih aman terhadap risiko nilai NULL pada subquery.
-- Alternatif: NOT IN; digunakan sebagai perbandingan sesuai permintaan soal.

-- Versi 1: Menggunakan NOT IN
SELECT title
FROM film
WHERE film_id NOT IN (
    SELECT i.film_id
    FROM inventory i
    JOIN rental r ON i.inventory_id = r.inventory_id
);

-- Versi 2: Menggunakan NOT EXISTS
SELECT f.title
FROM film f
WHERE NOT EXISTS (
    SELECT 1
    FROM inventory i
    JOIN rental r ON i.inventory_id = r.inventory_id
    WHERE i.film_id = f.film_id
);