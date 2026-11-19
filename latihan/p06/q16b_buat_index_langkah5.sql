-- Index langkah 5 (sesuai soal)
CREATE INDEX ON lab6.event_log USING gin (payload jsonb_path_ops);
CREATE INDEX ON lab6.event_log USING gin (tags);
CREATE INDEX ON lab6.event_log USING brin (terjadi_pada) WITH (pages_per_range=128);
-- B-Tree polos pada terjadi_pada (sudah ada dari Q12; baris ini aman diulang)
CREATE INDEX IF NOT EXISTS ev_terjadi_plain_idx ON lab6.event_log (terjadi_pada);
ANALYZE lab6.event_log;
-- Nama index otomatis: event_log_payload_idx, event_log_tags_idx, event_log_terjadi_pada_idx
\di+ lab6.*
