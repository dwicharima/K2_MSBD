-- Diminta: untuk setiap pelanggan, tampilkan urutan pembayaran, jarak hari
--          sejak pembayaran sebelumnya, dan total belanja pelanggan sebagai
--          kolom pendamping di setiap baris.
-- Dipilih: PARTITION BY customer_id untuk memisahkan tiap pelanggan;
--          ROW_NUMBER untuk urutan, LAG untuk pembayaran sebelumnya,
--          dan frame seluruh partisi (UNBOUNDED PRECEDING..UNBOUNDED FOLLOWING)
--          supaya total_belanja sama di semua baris pelanggan tsb, bukan running total.

SELECT
    p.customer_id,
    p.payment_id,
    p.payment_date,
    ROW_NUMBER() OVER (PARTITION BY p.customer_id ORDER BY p.payment_date) AS urutan_pembayaran,
    (p.payment_date::date - LAG(p.payment_date) OVER (PARTITION BY p.customer_id ORDER BY p.payment_date)::date) AS jarak_hari,
    SUM(p.amount) OVER (
        PARTITION BY p.customer_id
        ORDER BY p.payment_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS total_belanja
FROM payment p
ORDER BY p.customer_id, p.payment_date;