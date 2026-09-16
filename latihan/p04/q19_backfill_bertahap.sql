-- Diminta: Lakukan backfill bertahap 1000 baris dan jalankan query verifikasi hingga bernilai nol.
-- Dipilih: INSERT INTO ... WHERE BETWEEN AND NOT EXISTS secara bertahap untuk mencegah penguncian tabel utama.
-- Alternatif: Single UPDATE massal; tidak dipilih karena dapat memblokir transaksi aktif di lingkungan produksi.

-- 1. Eksekusi Backfill Potongan 1000 Film
INSERT INTO lab4.harga_film (film_id, wilayah, harga, berlaku)
SELECT f.film_id, 'ID', f.rental_rate, daterange('2026-01-01', NULL)
FROM lab4.film f
WHERE f.film_id BETWEEN 1 AND 1000
  AND NOT EXISTS (
      SELECT 1 FROM lab4.harga_film h
      WHERE h.film_id = f.film_id AND h.wilayah = 'ID'
  );

-- 2. Query Verifikasi (Target: 0 baris)
SELECT count(*) AS sisa_belum_terisi
FROM lab4.film f
WHERE NOT EXISTS (
    SELECT 1 FROM lab4.harga_film h
    WHERE h.film_id = f.film_id AND h.wilayah = 'ID'
);