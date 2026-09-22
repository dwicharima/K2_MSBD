-- Diminta: Menangkap galat foreign_key_violation dan memberikan pesan ramah.
-- Dipilih: Blok EXCEPTION WHEN foreign_key_violation di dalam PL/pgSQL.
-- Alternatif: Validasi manual SELECT COUNT(*) sebelum INSERT; tidak dipilih karena memicu race condition.

CREATE OR REPLACE PROCEDURE lab5.process_rental_safe(
  p_customer_id integer,
  p_inventory_id integer,
  p_staff_id integer,
  p_amount numeric
)
LANGUAGE plpgsql AS $$
DECLARE
  v_rental_id bigint;
BEGIN
  -- Insert ke rental_tx
  INSERT INTO lab5.rental_tx (customer_id, inventory_id, staff_id)
  VALUES (p_customer_id, p_inventory_id, p_staff_id)
  RETURNING rental_id INTO v_rental_id;

  -- Insert ke payment_tx
  INSERT INTO lab5.payment_tx (rental_id, amount)
  VALUES (v_rental_id, p_amount);

EXCEPTION
  WHEN foreign_key_violation THEN
    RAISE EXCEPTION 'Gagal memproses penyewaan: Pelanggan, inventaris, atau staf tidak ditemukan.'
      USING HINT = 'Pastikan customer_id, inventory_id, dan staff_id yang dimasukkan valid.',
            ERRCODE = 'foreign_key_violation';
END;
$$;