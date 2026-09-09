-- Diminta: menampilkan film_id yang ada di inventory tetapi tidak pernah muncul melalui rental dan arah sebaliknya dalam satu hasil dengan penanda arah.
-- Dipilih: EXCEPT untuk mencari perbedaan antara dua himpunan film_id dan UNION ALL untuk menggabungkan hasil dari kedua arah.
-- Alternatif: FULL OUTER JOIN; tidak dipilih karena operasi himpunan lebih langsung dan sesuai dengan petunjuk soal.

SELECT
    film_id,
    'inventory_tidak_pernah_rental' AS arah
FROM (
    SELECT DISTINCT film_id
    FROM inventory

    EXCEPT

    SELECT DISTINCT i.film_id
    FROM rental r
    JOIN inventory i
        ON r.inventory_id = i.inventory_id
) AS inventory_tidak_rental

UNION ALL

SELECT
    film_id,
    'rental_tidak_ada_di_inventory' AS arah
FROM (
    SELECT DISTINCT i.film_id
    FROM rental r
    JOIN inventory i
        ON r.inventory_id = i.inventory_id

    EXCEPT

    SELECT DISTINCT film_id
    FROM inventory
) AS rental_tidak_inventory;