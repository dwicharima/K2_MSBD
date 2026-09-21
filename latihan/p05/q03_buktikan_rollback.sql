-- Diminta: Membuktikan rollback transaksi saat p_amount bernilai negatif pada lab5.process_rental.
-- Dipilih: Melakukan pemanggilan dengan nilai negatif, menyalin galat, dan menghitung jumlah baris rental_tx.
-- Alternatif: Menggunakan try-catch blok di PL/pgSQL; tidak dipilih karena langsung diuji lewat eksekusi luar.

-- Pemanggilan yang memicu galat (amount negatif -4.99)
CALL lab5.process_rental(
    p_customer_id := 1,
    p_inventory_id := 1,
    p_staff_id := 1,
    p_amount := -4.99
);

-- Menghitung jumlah data setelah rollback terjadi
SELECT count(*) AS jumlah_rental FROM lab5.rental_tx;