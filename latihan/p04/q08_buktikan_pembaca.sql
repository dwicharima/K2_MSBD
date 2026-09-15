-- Diminta: membuktikan bahwa REFRESH MATERIALIZED VIEW CONCURRENTLY tidak
-- memblokir pembaca, kemudian membandingkannya dengan refresh biasa.

-- Dipilih: dua sesi PostgreSQL digunakan agar SELECT pada sesi 2 dapat
-- dijalankan ketika refresh pada sesi 1 sedang berlangsung. Perbandingan
-- dilakukan antara REFRESH CONCURRENTLY dan REFRESH biasa untuk melihat
-- perbedaan perilaku lock terhadap pembaca.

-- Alternatif: menjalankan refresh dan SELECT secara berurutan dalam satu sesi;
-- tidak dipilih karena tidak dapat membuktikan apakah pembaca terblokir selama
-- proses refresh berlangsung.

-- ============================================================
-- SESI 1
-- ============================================================

INSERT INTO lab4.jejak_akses (film_id, waktu, kanal)
SELECT (random() * 999)::int + 1,
       now(),
       'web'
FROM generate_series(1, 200000);

-- Refresh concurrent.
REFRESH MATERIALIZED VIEW CONCURRENTLY lab4.ringkasan_akses;


-- ============================================================
-- SESI 2
-- Jalankan segera setelah refresh pada sesi 1 dimulai.
-- ============================================================

SELECT count(*)
FROM lab4.ringkasan_akses;