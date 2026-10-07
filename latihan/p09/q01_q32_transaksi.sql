-- Q1: Buktikan kondisi awal & total saldo
SELECT * FROM lab9.rekening ORDER BY rekening_id;
SELECT SUM(saldo) AS total_saldo FROM lab9.rekening;

-- Q2: BEGIN, update saldo, cek di sesi lain (belum commit)
-- Di Sesi A:
BEGIN;
UPDATE lab9.rekening SET saldo = saldo - 200000 WHERE rekening_id = 1;
SELECT * FROM lab9.rekening ORDER BY rekening_id;
-- Di Sesi B:
SELECT * FROM lab9.rekening ORDER BY rekening_id;

-- Q3: Bandingkan COMMIT dan ROLLBACK
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

-- Q4: SAVEPOINT dan ROLLBACK TO SAVEPOINT
BEGIN;
-- Perubahan 1
UPDATE lab9.rekening SET saldo = saldo + 50000 WHERE rekening_id = 1;

SAVEPOINT sp_satu;

-- Perubahan 2 (yang akan dibatalkan)
UPDATE lab9.rekening SET saldo = saldo + 500000 WHERE rekening_id = 1;

-- Batalkan hanya sampai savepoint
ROLLBACK TO SAVEPOINT sp_satu;

SELECT * FROM lab9.rekening ORDER BY rekening_id;
COMMIT;

