-- 1. Ubah harga sungguhan -> harus tercatat
UPDATE lab4.film SET rental_rate = 2.99 WHERE title = 'Film A';

-- 2. Tulis ulang harga sama persis -> TIDAK tercatat (ditahan WHEN)
UPDATE lab4.film SET rental_rate = 2.99 WHERE title = 'Film A';

-- 3. Ubah title saja -> TIDAK tercatat (trigger tidak fire sama sekali,
--    karena rental_rate tidak disebut di SET)
UPDATE lab4.film SET title = 'Film A Updated' WHERE title = 'Film A';

SELECT * FROM lab4.audit_harga;