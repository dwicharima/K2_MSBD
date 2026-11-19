-- Diminta: menjadikan query Q5 sebagai materialized view dengan WITH NO DATA,
-- membuktikan bahwa matview belum dapat dibaca sebelum refresh, kemudian
-- melakukan refresh biasa dan mencatat waktunya.

-- Dipilih: CREATE MATERIALIZED VIEW ... WITH NO DATA agar materialized view
-- dibuat terlebih dahulu tanpa mengisi hasil query, kemudian REFRESH MATERIALIZED
-- VIEW digunakan untuk mengisi hasil agregasinya.

-- Alternatif: CREATE MATERIALIZED VIEW tanpa WITH NO DATA; tidak dipilih karena
-- soal secara khusus meminta kondisi awal matview kosong sebelum dilakukan refresh.

\timing on

CREATE MATERIALIZED VIEW lab4.ringkasan_akses AS
SELECT date_trunc('month', a.waktu) AS bulan,
       a.kanal,
       count(*) AS jumlah_akses,
       count(DISTINCT a.film_id) AS film_unik
FROM lab4.jejak_akses a
GROUP BY 1, 2
ORDER BY 1, 2
WITH NO DATA;

-- Coba membaca materialized view sebelum refresh.
SELECT *
FROM lab4.ringkasan_akses;

-- Isi materialized view dengan hasil query.
REFRESH MATERIALIZED VIEW lab4.ringkasan_akses;