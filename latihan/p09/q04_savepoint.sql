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