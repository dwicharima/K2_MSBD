-- Diminta: Mengembalikan struktur tabel ke kondisi sebelum dibuatnya View Fasad.
-- Dipilih: DROP VIEW lab4.film lalu RENAME kembali film_base menjadi film.
-- Alternatif: Membiarkan view; tidak dipilih karena rollback harus memulihkan nama entitas asli.

DROP VIEW IF EXISTS lab4.film;
ALTER TABLE lab4.film_base RENAME TO film;