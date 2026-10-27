-- [PERSIAPAN]
UPDATE lab9.rekening SET saldo = 1000000 WHERE rekening_id = 1;

-- LANGKAH 1 [SESI A]
BEGIN;
UPDATE lab9.rekening SET saldo = saldo - 300000 WHERE rekening_id = 1;
SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;

-- LANGKAH 2 [SESI B]
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; 
SHOW transaction_isolation;
SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;
COMMIT;

-- LANGKAH 3 [SESI A]
ROLLBACK;
SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;

