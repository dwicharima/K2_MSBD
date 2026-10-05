SELECT attname, correlation, n_distinct
FROM pg_stats WHERE schemaname='lab6' AND tablename='event_log' AND attname='terjadi_pada';
SELECT c.relname, am.amname, c.relpages, pg_relation_size(c.oid) AS bytes,
        pg_size_pretty(pg_relation_size(c.oid)) AS ukuran
FROM pg_index i
JOIN pg_class c ON c.oid=i.indexrelid
JOIN pg_am am ON am.oid=c.relam
WHERE i.indrelid='lab6.event_log'::regclass
  AND c.relname IN ('event_log_terjadi_pada_idx','ev_terjadi_plain_idx');
SELECT round(100.0*pg_relation_size('lab6.event_log_terjadi_pada_idx')
              /pg_relation_size('lab6.ev_terjadi_plain_idx'),3) AS brin_persen_dari_btree,
        round(pg_relation_size('lab6.ev_terjadi_plain_idx')::numeric
              /pg_relation_size('lab6.event_log_terjadi_pada_idx'),1) AS btree_kali_brin;
