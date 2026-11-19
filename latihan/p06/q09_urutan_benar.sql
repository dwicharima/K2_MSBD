DROP INDEX lab6.ev_salah_idx;
CREATE INDEX ev_benar_idx ON lab6.event_log (customer_id, terjadi_pada DESC);
ANALYZE lab6.event_log;
INSERT INTO lab6.p06_ukuran_index(label, bytes) VALUES ('ev_benar_idx', pg_relation_size('lab6.ev_benar_idx'));
SELECT 'ev_benar_idx' AS index, pg_size_pretty(pg_relation_size('lab6.ev_benar_idx')) AS ukuran, pg_relation_size('lab6.ev_benar_idx') AS bytes;
