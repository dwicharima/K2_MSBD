-- Diminta: Jalankan ulang Q13 tanpa klausa frame sehingga memakai RANGE default.
--          Temukan tanggal yang hasilnya berbeda dari Q13 dan catat jumlahnya.
--
-- Dipilih: dua CTE hasil (q13_hasil = frame eksplisit ROWS seperti Q13 asli,
--          q14_hasil = ORDER BY saja tanpa frame, sehingga Postgres memakai
--          default RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW).
--          Dibandingkan dengan FULL JOIN pada tanggal, lalu difilter baris yang
--          nilainya beda memakai IS DISTINCT FROM (aman terhadap NULL).
--
-- Alternatif: EXCEPT/UNION ALL; tidak dipilih karena FULL JOIN langsung
--          menampilkan nilai Q13 vs Q14 berdampingan per tanggal, lebih mudah
--          dipakai untuk menjelaskan penyebab perbedaannya.

WITH daily_revenue AS (
    SELECT
        payment_date::date AS tanggal,
        SUM(amount) AS omzet
    FROM payment
    GROUP BY payment_date::date
),
q13_hasil AS (
    SELECT
        tanggal,
        omzet,
        SUM(omzet) OVER (
            ORDER BY tanggal
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS omzet_kumulatif,
        ROUND(
            AVG(omzet) OVER (
                ORDER BY tanggal
                ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
            ),
            2
        ) AS rata_rata_7_hari
    FROM daily_revenue
),
q14_hasil AS (
    SELECT
        tanggal,
        omzet,
        SUM(omzet) OVER (
            ORDER BY tanggal
        ) AS omzet_kumulatif,
        ROUND(
            AVG(omzet) OVER (
                ORDER BY tanggal
            ),
            2
        ) AS rata_rata_7_hari
    FROM daily_revenue
)
SELECT
    q13.tanggal,
    q13.omzet_kumulatif   AS kumulatif_q13,
    q14.omzet_kumulatif   AS kumulatif_q14,
    q13.rata_rata_7_hari  AS rerata7_q13,
    q14.rata_rata_7_hari  AS rerata7_q14
FROM q13_hasil q13
FULL JOIN q14_hasil q14 ON q14.tanggal = q13.tanggal
WHERE q13.omzet_kumulatif  IS DISTINCT FROM q14.omzet_kumulatif
    OR q13.rata_rata_7_hari IS DISTINCT FROM q14.rata_rata_7_hari
ORDER BY q13.tanggal;

-- Catatan jumlah tanggal yang berbeda:
WITH daily_revenue AS (
    SELECT
        payment_date::date AS tanggal,
        SUM(amount) AS omzet
    FROM payment
    GROUP BY payment_date::date
),
q13_hasil AS (
    SELECT
        tanggal,
        SUM(omzet) OVER (
            ORDER BY tanggal
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS omzet_kumulatif,
        ROUND(
            AVG(omzet) OVER (
                ORDER BY tanggal
                ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
            ),
            2
        ) AS rata_rata_7_hari
    FROM daily_revenue
),
q14_hasil AS (
    SELECT
        tanggal,
        SUM(omzet) OVER (ORDER BY tanggal) AS omzet_kumulatif,
        ROUND(AVG(omzet) OVER (ORDER BY tanggal), 2) AS rata_rata_7_hari
    FROM daily_revenue
)
SELECT COUNT(*) AS jumlah_tanggal_berbeda
FROM q13_hasil q13
FULL JOIN q14_hasil q14 ON q14.tanggal = q13.tanggal
WHERE q13.omzet_kumulatif  IS DISTINCT FROM q14.omzet_kumulatif
    OR q13.rata_rata_7_hari IS DISTINCT FROM q14.rata_rata_7_hari;