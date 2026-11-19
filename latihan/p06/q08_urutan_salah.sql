CREATE TABLE IF NOT EXISTS lab6.p06_ukuran_index (label text, bytes bigint, dicatat timestamptz DEFAULT now());
CREATE INDEX ev_salah_idx ON lab6.event_log (terjadi_pada, customer_id);
ANALYZE lab6.event_log;
INSERT INTO lab6.p06_ukuran_index(label, bytes) VALUES ('ev_salah_idx', pg_relation_size('lab6.ev_salah_idx'));
SELECT 'ev_salah_idx' AS index, pg_size_pretty(pg_relation_size('lab6.ev_salah_idx')) AS ukuran, pg_relation_size('lab6.ev_salah_idx') AS bytes;
