-- PERSIAPAN
UPDATE lab9.rekening SET saldo = 1000000 WHERE rekening_id = 1;

-- [SESI A]
BEGIN;
SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;

-- [SESI B]
BEGIN;
SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;

-- [SESI A]
UPDATE lab9.rekening SET saldo = 1100000 WHERE rekening_id = 1;
COMMIT;

-- [SESI B] 
UPDATE lab9.rekening SET saldo = 1200000 WHERE rekening_id = 1;
COMMIT;

-- HASIL
SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;

-- PENCEGAHAN
UPDATE lab9.rekening SET saldo = 1000000 WHERE rekening_id = 1;
UPDATE lab9.rekening SET saldo = saldo + 100000 WHERE rekening_id = 1;
UPDATE lab9.rekening SET saldo = saldo + 200000 WHERE rekening_id = 1;
SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;

-- RESET
UPDATE lab9.rekening SET saldo = 1000000 WHERE rekening_id = 1;