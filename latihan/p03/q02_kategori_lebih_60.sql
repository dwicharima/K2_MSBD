-- Diminta: mencari kategori dengan jumlah film lebih dari 60.
-- Dipilih: derived table di FROM; menunjukkan perbandingan dengan membungkus query grouping ke dalam subquery.
-- Alternatif & Perbandingan : Lebih panjang dan kurang rapi karena harus bikin alias tabel turunan (`AS sub`) cuma buat nge-filter hasil `COUNT` di luar.

SELECT kategori, jumlah_film
FROM (
    SELECT c.name AS kategori, COUNT(f.film_id) AS jumlah_film
    FROM category c
    JOIN film_category fc ON c.category_id = fc.category_id
    JOIN film f ON fc.film_id = f.film_id
    GROUP BY c.name
) AS sub
WHERE jumlah_film > 60;

-- Diminta: mencari kategori dengan jumlah film lebih dari 60.
-- Dipilih: HAVING karena lebih ringkas dan langsung menyaring hasil agregasi.
-- Alternatif & Perbandingan : Jauh lebih bersih dan natural dibaca karena filter langsung nempel di proses grouping.

SELECT c.name AS kategori, COUNT(f.film_id) AS jumlah_film
FROM category c
JOIN film_category fc ON c.category_id = fc.category_id
JOIN film f ON fc.film_id = f.film_id
GROUP BY c.name
HAVING COUNT(f.film_id) > 60;