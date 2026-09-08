-- Diminta: menampilkan omzet harian, omzet hari sebelumnya, selisih omzet,
-- dan persentase perubahan omzet.
--
-- Dipilih: LAG dengan nilai pengganti 0 digunakan untuk mengambil omzet hari
-- sebelumnya. Perhitungan dilakukan pada CTE agar hasil LAG dapat digunakan
-- kembali pada query luar.
--
-- Alternatif: self join berdasarkan tanggal untuk mencari omzet hari sebelumnya;
-- tidak dipilih karena LAG lebih sederhana dan memang dirancang untuk kebutuhan ini.

WITH daily_revenue AS (
    SELECT
        payment_date::date AS tanggal,
        SUM(amount) AS omzet
    FROM payment
    GROUP BY payment_date::date
),
revenue_change AS (
    SELECT
        tanggal,
        omzet,
        LAG(omzet, 1, 0) OVER (
            ORDER BY tanggal
        ) AS omzet_hari_sebelumnya
    FROM daily_revenue
)
SELECT
    tanggal,
    omzet,
    omzet_hari_sebelumnya,
    omzet - omzet_hari_sebelumnya AS selisih,
    CASE
        WHEN omzet_hari_sebelumnya = 0 THEN NULL
        ELSE ROUND(
            (omzet - omzet_hari_sebelumnya)
            / omzet_hari_sebelumnya * 100,
            2
        )
    END AS persentase_perubahan
FROM revenue_change
ORDER BY tanggal;