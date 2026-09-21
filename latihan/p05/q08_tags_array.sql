-- Diminta: mengedit kolom tags (array) dengan 3 nilai dan melakukan pencarian menggunakan operator array.
-- Dipilih: operator `= ANY()` untuk memeriksa keberadaan elemen di dalam array secara langsung.
-- Alternatif: operator containment `@>`; tidak dipilih karena `= ANY()` lebih eksplisit untuk pencarian tunggal.

-- 1. Isi tags dengan tiga nilai
UPDATE lab5.rental_tx 
SET tags = ARRAY['promo', 'akhir-pekan', 'anggota'] 
WHERE rental_id = 1;

-- 2. Cari baris yang memiliki tag 'promo'
SELECT rental_id, tags 
FROM lab5.rental_tx 
WHERE 'promo' = ANY(tags);

/* Hasil Keluaran:
 rental_id |           tags           
-----------+--------------------------
         1 | {promo,akhir-pekan,anggota}
(1 row)
*/