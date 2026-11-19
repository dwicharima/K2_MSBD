-- Q16: dijalankan MANUAL di dua sesi.
-- [PERSIAPAN]
UPDATE lab9.rekening SET saldo = 1000000 WHERE rekening_id IN (1,2);
-- [SESI A] kondisi awal
SELECT xmin, xmax, ctid, rekening_id, saldo FROM lab9.rekening ORDER BY rekening_id;
-- [SESI B] update tanpa COMMIT
BEGIN;
UPDATE lab9.rekening SET saldo = saldo + 1 WHERE rekening_id = 1;
SELECT pg_current_xact_id() AS xid_sesi_b;
SELECT xmin, xmax, ctid, saldo FROM lab9.rekening WHERE rekening_id = 1;
-- [SESI A] xmax terisi (in progress), baris tetap terlihat
SELECT xmin, xmax, ctid, saldo, pg_xact_status(xmax::text::xid8) AS status_xmax
FROM lab9.rekening WHERE rekening_id = 1;
-- [SESI B]
ROLLBACK;
-- [SESI A] xmax tetap terisi (aborted), baris tetap terlihat
SELECT xmin, xmax, ctid, saldo, pg_xact_status(xmax::text::xid8) AS status_xmax
FROM lab9.rekening WHERE rekening_id = 1;
-- [SESI A] xmax juga terisi oleh row lock
BEGIN;
SELECT pg_current_xact_id() AS xid_sesi_a;
SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 2 FOR UPDATE;
-- [SESI B]
SELECT xmin, xmax, ctid, saldo FROM lab9.rekening WHERE rekening_id = 2;
-- [SESI A]
ROLLBACK;