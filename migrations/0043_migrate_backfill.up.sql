-- Diminta: menyalin data historis rental_rate dari tabel film ke harga_film.
-- Dipilih: INSERT INTO ... SELECT bertahap memakai NOT EXISTS yang memeriksa periode 'ID' yang sedang berlaku hari ini, bukan sekadar pernah ada baris ID -- supaya film dengan riwayat harga kedaluwarsa tetap ter-backfill.
-- Alternatif: NOT EXISTS tanpa syarat periode aktif; tidak dipilih karena terbukti membuat film dengan entri harga lama yang sudah kedaluwarsa dilewati begitu saja.

INSERT INTO lab4.harga_film (film_id, wilayah, harga, berlaku)
SELECT f.film_id, 'ID', f.rental_rate, daterange(CURRENT_DATE, NULL, '[)')
FROM lab4.film f
WHERE f.film_id BETWEEN 1 AND 1000
  AND NOT EXISTS (
      SELECT 1 FROM lab4.harga_film h
      WHERE h.film_id = f.film_id
        AND h.wilayah = 'ID'
        AND h.berlaku @> CURRENT_DATE
  );