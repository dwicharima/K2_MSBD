-- Q15: dijalankan MANUAL di dua sesi. Catatan: \timing on dan \timing off
-- diketik SENDIRIAN di satu baris (jangan digabung dengan SQL lain).
-- [PERSIAPAN]
UPDATE lab9.rekening SET saldo = 1000000 WHERE rekening_id IN (1,2);
-- [SESI A]
\timing on
-- [SESI A]
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;
SELECT pg_current_snapshot();
-- [SESI B] belum COMMIT
BEGIN;
UPDATE lab9.rekening SET saldo = saldo + 100000 WHERE rekening_id = 1;
SELECT pg_current_xact_id() AS xid_sesi_b;
SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;
-- [SESI A] langsung kembali, tetap 1000000
SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;
-- [SESI B]
COMMIT;
-- [SESI A] masih 1000000, snapshot sama
SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;
SELECT pg_current_snapshot();
SELECT mode, granted FROM pg_locks
WHERE pid = pg_backend_pid() AND locktype = 'relation' AND relation = 'lab9.rekening'::regclass;
COMMIT;
SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;   -- kini 1100000
-- [SESI A]
\timing off
-- [RESET]
UPDATE lab9.rekening SET saldo = 1000000 WHERE rekening_id IN (1,2);