-- Diminta: Menyalin data historis rental_rate dari tabel film ke harga_film.
-- Dipilih: INSERT INTO ... SELECT bertahap memakai klausa NOT EXISTS untuk menghindari duplikasi.
-- Alternatif: Single UPDATE massal tanpa saringan; tidak dipilih karena berpotensi memblokir akses tabel utama.

INSERT INTO lab4.harga_film (film_id, wilayah, harga, berlaku)
SELECT f.film_id, 'ID', f.rental_rate, daterange('2026-01-01', NULL)
FROM lab4.film f
WHERE f.film_id BETWEEN 1 AND 1000
  AND NOT EXISTS (
      SELECT 1 FROM lab4.harga_film h
      WHERE h.film_id = f.film_id AND h.wilayah = 'ID'
  );