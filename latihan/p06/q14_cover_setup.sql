CREATE INDEX ev_cover_idx ON lab6.event_log (customer_id) INCLUDE (terjadi_pada,jumlah);
INSERT INTO lab6.p06_ukuran_index(label, bytes) VALUES ('ev_cover_idx', pg_relation_size('lab6.ev_cover_idx'));
ALTER TABLE lab6.event_log SET (autovacuum_enabled = false);
VACUUM (ANALYZE) lab6.event_log;
UPDATE lab6.event_log SET jumlah = jumlah WHERE customer_id = 4211;
SELECT relpages, relallvisible FROM pg_class WHERE oid = 'lab6.event_log'::regclass;
SELECT pg_size_pretty(pg_relation_size('lab6.ev_cover_idx')) AS ukuran_ev_cover_idx;
