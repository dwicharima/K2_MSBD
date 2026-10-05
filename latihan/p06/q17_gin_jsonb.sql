EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*) FROM lab6.event_log WHERE payload @> '{"promo": true}';
