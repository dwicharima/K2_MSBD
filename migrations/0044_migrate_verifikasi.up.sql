-- Diminta: memeriksa apakah masih ada baris pada tabel film yang belum memiliki harga wilayah ID yang sedang berlaku.
-- Dipilih: query SELECT count(*) dengan NOT EXISTS yang harus mengembalikan nilai 0; syarat berlaku @> CURRENT_DATE memastikan yang dihitung adalah harga AKTIF, bukan sekadar pernah ada baris.
-- Alternatif: membandingkan total jumlah baris (count) tanpa cek periode aktif; tidak dipilih karena tidak menjamin film benar-benar punya harga yang valid hari ini.

SELECT count(*) AS sisa_belum_terisi
FROM lab4.film f
WHERE NOT EXISTS (
    SELECT 1 FROM lab4.harga_film h
    WHERE h.film_id = f.film_id
      AND h.wilayah = 'ID'
      AND h.berlaku @> CURRENT_DATE
);