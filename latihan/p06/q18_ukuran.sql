SELECT pg_size_pretty(pg_relation_size('lab6.event_log_tags_idx')) AS gin_tags;
SELECT count(*) AS baris_cocok, round(100.0*count(*)/2000000,2) AS persen
FROM lab6.event_log WHERE tags @> ARRAY['kanal:1','sumber:2'];
