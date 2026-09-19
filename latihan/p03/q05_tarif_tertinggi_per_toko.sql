-- Diminta: Untuk setiap toko, tampilkan judul film dengan tarif sewa tertinggi di toko tersebut tanpa window function.
-- Dipilih: subquery berkorelasi dengan MAX karena lebih intuitif dan langsung mencocokkan tarif dengan nilai maksimum di toko yang sama.
-- Alternatif: menggunakan = ALL; tidak dipilih karena sintaksisnya lebih panjang dibanding MAX.

SELECT DISTINCT s.store_id, f.title, f.rental_rate
FROM store s
JOIN inventory i ON s.store_id = i.store_id
JOIN film f ON i.film_id = f.film_id
WHERE f.rental_rate = (
    SELECT MAX(f_sub.rental_rate)
    FROM inventory i_sub
    JOIN film f_sub ON i_sub.film_id = f_sub.film_id
    WHERE i_sub.store_id = s.store_id
);