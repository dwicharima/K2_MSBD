-- Diminta: Membuat salinan procedure yang menjalankan COMMIT di tengah eksekusi (setelah insert pertama).
-- Dipilih: Menggunakan CREATE OR REPLACE PROCEDURE dengan menyisipkan COMMIT di antara INSERT rental_tx dan payment_tx.
-- Alternatif: Tanpa COMMIT; tidak dipilih karena tujuan soal adalah mendemonstrasikan galat transaksi.

CREATE OR REPLACE PROCEDURE lab5.process_rental_with_commit(
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
      USING ERRCODE = '22003';
  END IF;

  INSERT INTO lab5.rental_tx (customer_id, inventory_id, staff_id, metadata)
  VALUES (p_customer_id, p_inventory_id, p_staff_id,
          coalesce(p_metadata, '{}'::jsonb))
  RETURNING rental_id INTO p_rental_id;

  -- Sengaja menyisipkan COMMIT di tengah procedure
  COMMIT;

  INSERT INTO lab5.payment_tx (rental_id, amount)
  VALUES (p_rental_id, p_amount);
END;
$$;

