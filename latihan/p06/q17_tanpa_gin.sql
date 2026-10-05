BEGIN;
DROP INDEX lab6.event_log_payload_idx;
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*) FROM lab6.event_log WHERE payload @> '{"promo": true}';
ROLLBACK;
