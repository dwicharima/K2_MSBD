-- Diminta: mencari nama pelanggan yang pernah melakukan pembayaran lebih dari 9.99 dalam satu transaksi.
-- Dipilih: EXISTS berkorelasi karena efisien mengecek keberadaan data tanpa menghasilkan duplikat baris.
-- Alternatif: JOIN dengan DISTINCT; tidak dipilih karena melanggar petunjuk soal dan kurang efisien.

SELECT first_name, last_name
FROM customer c
WHERE EXISTS (
    SELECT 1 
    FROM payment p 
    WHERE p.customer_id = c.customer_id 
      AND p.amount > 9.99
);