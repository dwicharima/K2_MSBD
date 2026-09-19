-- Diminta: mencari film dengan tarif di atas rata-rata beserta judul, tarif, rata-rata, dan selisihnya, diurutkan menurun.
-- Dipilih: subquery skalar di SELECT dan WHERE karena cocok untuk membandingkan baris tunggal dengan nilai agregat global.
-- Alternatif: menggunakan window function AVG() OVER(); tidak dipilih karena petunjuk soal mengarahkan penggunaan subquery skalar.

SELECT 
    title,
    rental_rate,
    (SELECT avg(rental_rate) FROM film) AS rata_rata,
    rental_rate - (SELECT avg(rental_rate) FROM film) AS selisih
FROM film
WHERE rental_rate > (SELECT avg(rental_rate) FROM film)
ORDER BY rental_rate DESC;