-- Diminta: menulis ulang Q2 (kategori dengan jumlah film lebih dari 60) memakai CTE,
--          lalu menambahkan CTE kedua yang menghitung rata-rata tarif sewa per kategori.
-- Dipilih: dua CTE berurutan. CTE pertama (kategori_lebih_60) menghitung jumlah film
--          per kategori dan menyaring yang lebih dari 60; CTE kedua (rata_tarif_kategori)
--          merujuk CTE pertama agar rata-rata hanya dihitung untuk kategori yang lolos saringan.
-- Alternatif: derived table bersarang (subquery di dalam subquery pada FROM); tidak dipilih
--          karena begitu ada dua tahap agregasi berurutan, tingkat indentasinya membuat
--          query jauh lebih sulit dibaca dibanding CTE yang bernama dan mengalir top-down.

WITH kategori_lebih_60 AS (
    SELECT c.category_id,
           c.name AS kategori,
           COUNT(f.film_id) AS jumlah_film
    FROM category c
    JOIN film_category fc ON fc.category_id = c.category_id
    JOIN film f ON f.film_id = fc.film_id
    GROUP BY c.category_id, c.name
    HAVING COUNT(f.film_id) > 60
),
rata_tarif_kategori AS (
    SELECT k.category_id,
           AVG(f.rental_rate) AS rata_tarif
    FROM kategori_lebih_60 k
    JOIN film_category fc ON fc.category_id = k.category_id
    JOIN film f ON f.film_id = fc.film_id
    GROUP BY k.category_id
)
SELECT k.kategori,
       k.jumlah_film,
       r.rata_tarif
FROM kategori_lebih_60 k
JOIN rata_tarif_kategori r ON r.category_id = k.category_id
ORDER BY k.kategori;
