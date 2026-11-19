-- [PERSIAPAN]
UPDATE lab9.rekening SET saldo = 1000000 WHERE rekening_id = 1;

-- LANGKAH 1 [SESI A]
BEGIN ISOLATION LEVEL REPEATABLE READ;
SHOW transaction_isolation;  
SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;  


-- LANGKAH 2 [SESI B]
UPDATE lab9.rekening SET saldo = saldo + 100000 WHERE rekening_id = 1;

-- LANGKAH 3 [SESI A]
SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;
COMMIT;

-- LANGKAH 4 [SESI A]
SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;

-- [RESET]
UPDATE lab9.rekening SET saldo = 1000000 WHERE rekening_id = 1;
