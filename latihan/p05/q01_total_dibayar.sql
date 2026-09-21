-- Diminta: menulis function lab5.total_dibayar(p_rental_id bigint) untuk menghitung total pembayaran suatu penyewaan.
-- Dipilih: menggunakan fungsi SQL STABLE dengan coalesce untuk menangani nilai null.
-- Alternatif: prosedur PL/pgSQL; tidak dipilih karena fungsi SQL lebih ringkas dan efisien untuk query tunggal.

CREATE OR REPLACE FUNCTION lab5.total_dibayar(p_rental_id bigint)
RETURNS numeric LANGUAGE sql STABLE AS $$
SELECT coalesce(sum(amount), 0) FROM lab5.payment_tx WHERE rental_id = p_rental_id;
$$;