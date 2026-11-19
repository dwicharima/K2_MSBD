-- Diminta: menyisipkan satu film melalui view lab4.film_murah dengan rental_rate = 4.99, menghitung jumlah baris dengan judul yang sama di view dan tabel dasar, lalu menjelaskan selisihnya.
-- Dipilih: Melakukan INSERT melalui view tanpa check option dilanjutkan dengan query UNION ALL untuk menghitung baris di view dan tabel dasar agar silent filtering terlihat jelas.
-- Alternatif: Melakukan INSERT langsung ke tabel dasar; tidak dipilih karena tidak menguji perilaku mutasi data melalui view fasad.

INSERT INTO lab4.film_murah (title, rental_rate, rating)
VALUES ('Film Gaib Q2', 4.99, 'PG');

SELECT 'Di View' AS lokasi, count(*) FROM lab4.film_murah WHERE title = 'Film Gaib Q2'
UNION ALL
SELECT 'Di Tabel Dasar' AS lokasi, count(*) FROM lab4.film WHERE title = 'Film Gaib Q2';