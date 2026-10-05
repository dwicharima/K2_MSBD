BEGIN;
DROP INDEX lab6.ev_terjadi_plain_idx;
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*), sum(jumlah) FROM lab6.event_log
WHERE terjadi_pada >= '2024-03-01 00:00+07' AND terjadi_pada < '2024-03-08 00:00+07';
ROLLBACK;
