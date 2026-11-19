-- Q12: dijalankan MANUAL per langkah di dua sesi (A dan B), bukan sebagai satu file.
-- [PERSIAPAN]
UPDATE lab9.rekening SET saldo = 1000000 WHERE rekening_id IN (1,2);

-- 12a. PEMBANDING (lost update)
-- [SESI A]
BEGIN;
SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;
-- [SESI B]
BEGIN;
SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;
-- [SESI A]
UPDATE lab9.rekening SET saldo = 990000 WHERE rekening_id = 1;
COMMIT;
-- [SESI B]
UPDATE lab9.rekening SET saldo = 990000 WHERE rekening_id = 1;
COMMIT;
-- [HASIL] seharusnya 980000, hasil 990000
SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;
-- [RESET]
UPDATE lab9.rekening SET saldo = 1000000 WHERE rekening_id IN (1,2);

-- 12b. PERBAIKAN: update atomik
-- [SESI A]
BEGIN;
UPDATE lab9.rekening SET saldo = saldo - 10000 WHERE rekening_id = 1 AND saldo >= 10000;
-- [SESI B]
BEGIN;
UPDATE lab9.rekening SET saldo = saldo - 10000 WHERE rekening_id = 1 AND saldo >= 10000;
-- [SESI A]
COMMIT;
-- [SESI B]
COMMIT;
-- [HASIL] 980000
SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;

-- 12c. SALDO TIDAK CUKUP
-- [SESI A]
UPDATE lab9.rekening SET saldo = 15000 WHERE rekening_id = 1;
BEGIN;
UPDATE lab9.rekening SET saldo = saldo - 10000 WHERE rekening_id = 1 AND saldo >= 10000;
-- [SESI B]
BEGIN;
UPDATE lab9.rekening SET saldo = saldo - 10000 WHERE rekening_id = 1 AND saldo >= 10000;
-- [SESI A]
COMMIT;
-- [SESI B] hasil UPDATE 0
COMMIT;
-- [HASIL] 5000
SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;

-- [RESET]
UPDATE lab9.rekening SET saldo = 1000000 WHERE rekening_id IN (1,2);