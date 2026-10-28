-- Q13: dijalankan MANUAL di dua sesi + satu sesi pengamat.
-- [PERSIAPAN] di tiap sesi: SET application_name = 'Sesi A' / 'Sesi B' / 'Pengamat';
UPDATE lab9.rekening SET saldo = 1000000 WHERE rekening_id IN (1,2);

-- [SESI A]
BEGIN;
SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;
-- [SESI B] menunggu
BEGIN;
SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;
-- [PENGAMAT] saat Sesi B menunggu
SELECT b.application_name AS menunggu, b.wait_event_type, b.wait_event,
       a.application_name AS diblokir_oleh
FROM pg_stat_activity b
JOIN pg_stat_activity a ON a.pid = ANY (pg_blocking_pids(b.pid))
WHERE b.application_name LIKE 'Sesi%';
-- [SESI A]
UPDATE lab9.rekening SET saldo = 990000 WHERE rekening_id = 1;
COMMIT;
-- [SESI B] dilepas, membaca 990000
UPDATE lab9.rekening SET saldo = 980000 WHERE rekening_id = 1;
COMMIT;
-- [HASIL] 980000
SELECT rekening_id, saldo FROM lab9.rekening WHERE rekening_id = 1;

-- [RESET]
UPDATE lab9.rekening SET saldo = 1000000 WHERE rekening_id IN (1,2);