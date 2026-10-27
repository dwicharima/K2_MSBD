-- [PERSIAPAN]
UPDATE lab9.rekening SET saldo = 1000000 WHERE rekening_id IN (1,2);
SELECT * FROM lab9.rekening ORDER BY rekening_id;

-- LANGKAH 1 [SESI A]
BEGIN;
SHOW transaction_isolation;
SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;

-- LANGKAH 2 [SESI B] 
UPDATE lab9.rekening SET saldo = saldo + 100000 WHERE rekening_id = 1;
SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1; 

-- LANGKAH 3 [SESI A]  (SELECT yang sama lagi)
SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;
COMMIT;

-- [RESET]
UPDATE lab9.rekening SET saldo = 1000000 WHERE rekening_id = 1;
