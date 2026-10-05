SELECT pg_relation_size('lab6.event_log') AS bytes_heap,
        pg_relation_size('lab6.event_log_payload_idx') AS bytes_gin_payload,
        pg_size_pretty(pg_relation_size('lab6.event_log')) AS heap,
        pg_size_pretty(pg_relation_size('lab6.event_log_payload_idx')) AS gin_payload,
        round(100.0*pg_relation_size('lab6.event_log_payload_idx')/pg_relation_size('lab6.event_log'),2) AS persen_dari_heap;
SELECT count(*) AS baris_promo, round(100.0*count(*)/2000000,2) AS persen
FROM lab6.event_log WHERE payload @> '{"promo": true}';
