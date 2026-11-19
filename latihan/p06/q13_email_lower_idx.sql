CREATE INDEX ev_email_lower_idx ON lab6.event_log (lower(email));
ANALYZE lab6.event_log;
INSERT INTO lab6.p06_ukuran_index(label, bytes) VALUES ('ev_email_lower_idx', pg_relation_size('lab6.ev_email_lower_idx'));
SELECT pg_size_pretty(pg_relation_size('lab6.ev_email_lower_idx')) AS ukuran_ev_email_lower_idx;
