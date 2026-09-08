-- Diminta: menampilkan omzet harian, total omzet kumulatif sejak hari pertama,
-- dan rata-rata bergerak selama tujuh hari.
--
-- Dipilih: dua window function dengan frame ROWS yang berbeda, yaitu
-- UNBOUNDED PRECEDING untuk kumulatif dan 6 PRECEDING untuk rata-rata tujuh hari.
--
-- Alternatif: menggunakan subquery atau self join untuk menghitung omzet
-- kumulatif dan rata-rata; tidak dipilih karena window function lebih ringkas
-- dan langsung menggambarkan perhitungan berbasis urutan tanggal.

WITH daily_revenue AS (
    SELECT
        payment_date::date AS tanggal,
        SUM(amount) AS omzet
    FROM payment
    GROUP BY payment_date::date
)
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
ORDER BY tanggal;