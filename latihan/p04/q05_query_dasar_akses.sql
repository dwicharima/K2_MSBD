-- Diminta: menjalankan query agregasi akses berdasarkan bulan dan kanal,
-- serta mencatat waktu eksekusinya.

-- Dipilih: date_trunc untuk mengelompokkan waktu menjadi bulan, COUNT(*)
-- untuk menghitung seluruh akses, dan COUNT(DISTINCT film_id) untuk
-- menghitung jumlah film unik pada setiap kombinasi bulan dan kanal.

-- Alternatif: GROUP BY EXTRACT(YEAR FROM waktu), EXTRACT(MONTH FROM waktu);
-- tidak dipilih karena date_trunc menghasilkan nilai periode bulan secara
-- langsung dan lebih sederhana digunakan sebagai satu kolom pengelompokan.

\timing on

SELECT date_trunc('month', a.waktu) AS bulan,
       a.kanal,
       count(*) AS jumlah_akses,
       count(DISTINCT a.film_id) AS film_unik
FROM lab4.jejak_akses a
GROUP BY 1, 2
ORDER BY 1, 2;