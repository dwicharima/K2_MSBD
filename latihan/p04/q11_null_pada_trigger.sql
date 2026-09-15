CREATE OR REPLACE TRIGGER film_audit_harga
AFTER UPDATE OF rental_rate ON lab4.film
FOR EACH ROW
WHEN (OLD.rental_rate <> NEW.rental_rate)
EXECUTE FUNCTION lab4.catat_audit_harga();

ALTER TABLE lab4.film ALTER COLUMN rental_rate DROP NOT NULL;

UPDATE lab4.film SET rental_rate = NULL WHERE title = 'Film A Updated';   -- biasa -> NULL
UPDATE lab4.film SET rental_rate = 3.99 WHERE title = 'Film A Updated';  -- NULL -> biasa

SELECT * FROM lab4.audit_harga ORDER BY audit_id DESC LIMIT 5;

ALTER TABLE lab4.film ALTER COLUMN rental_rate SET NOT NULL;

-- Kembalikan ke versi aman untuk Q12–Q13
CREATE OR REPLACE TRIGGER film_audit_harga
AFTER UPDATE OF rental_rate ON lab4.film
FOR EACH ROW
WHEN (OLD.rental_rate IS DISTINCT FROM NEW.rental_rate)
EXECUTE FUNCTION lab4.catat_audit_harga();