-- Di Sesi A:
BEGIN;
UPDATE lab9.rekening SET saldo = saldo - 200000 WHERE rekening_id = 1;
SELECT * FROM lab9.rekening ORDER BY rekening_id;
-- Di Sesi B:
SELECT * FROM lab9.rekening ORDER BY rekening_id;