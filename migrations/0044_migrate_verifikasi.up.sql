-- Diminta: Memeriksa apakah masih ada baris pada tabel film yang belum tersalin ke harga_film.
-- Dipilih: Query SELECT count(*) dengan NOT EXISTS yang harus mengembalikan nilai 0.
-- Alternatif: Membandingkan total jumlah baris (count); tidak dipilih karena tidak menjamin kesesuaian antar ID.

SELECT count(*) AS sisa_belum_terisi
FROM lab4.film f
WHERE NOT EXISTS (
    SELECT 1 FROM lab4.harga_film h
    WHERE h.film_id = f.film_id AND h.wilayah = 'ID'
);