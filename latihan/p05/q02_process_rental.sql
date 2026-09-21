-- Diminta: menulis prosedur lab5.process_rental untuk memproses penyewaan baru dan mencatat pembayarannya secara transaksional.
-- Dipilih: menggunakan prosedur PL/pgSQL dengan blok transaksi eksplisit dan penanganan parameter input.
-- Alternatif: fungsi SQL biasa; tidak dipilih karena proses penyewaan melibatkan operasi INSERT multitabel dan manajemen transaksi (commit/rollback).

CREATE OR REPLACE PROCEDURE lab5.process_rental(
  IN p_customer_id  integer,
  IN p_inventory_id integer,
  IN p_staff_id     integer,
  IN p_amount       numeric(10,2),
  IN p_metadata     jsonb DEFAULT '{}'::jsonb,
  INOUT p_rental_id bigint DEFAULT NULL
) LANGUAGE plpgsql AS $$
BEGIN
  IF p_amount <= 0 THEN
    RAISE EXCEPTION 'nilai pembayaran harus positif, diterima %', p_amount
      USING ERRCODE = '22003';   -- numeric_value_out_of_range
  END IF;
  INSERT INTO lab5.rental_tx (customer_id, inventory_id, staff_id, metadata)
  VALUES (p_customer_id, p_inventory_id, p_staff_id,
          coalesce(p_metadata, '{}'::jsonb))
  RETURNING rental_id INTO p_rental_id;
  INSERT INTO lab5.payment_tx (rental_id, amount)
  VALUES (p_rental_id, p_amount);
  -- sengaja tidak ada COMMIT: batas transaksi milik pemanggil
END;
$$;