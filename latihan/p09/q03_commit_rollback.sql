-- COMMIT :
BEGIN;
UPDATE lab9.rekening SET saldo = saldo + 100000 WHERE rekening_id = 2;
COMMIT;
SELECT * FROM lab9.rekening ORDER BY rekening_id;
-- ROLLBACK :
BEGIN;
UPDATE lab9.rekening SET saldo = saldo - 500000 WHERE rekening_id = 2;
ROLLBACK;
SELECT * FROM lab9.rekening ORDER BY rekening_id;