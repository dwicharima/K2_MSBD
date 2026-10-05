EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*) FROM lab6.event_log WHERE tags @> ARRAY['kanal:1','sumber:2'];
