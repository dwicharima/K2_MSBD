CREATE INDEX ev_gagal_idx ON lab6.event_log (terjadi_pada DESC) WHERE status='GAGAL';
CREATE INDEX ev_terjadi_plain_idx ON lab6.event_log (terjadi_pada);
ANALYZE lab6.event_log;
INSERT INTO lab6.p06_ukuran_index(label, bytes) VALUES
 ('ev_gagal_idx', pg_relation_size('lab6.ev_gagal_idx')),
 ('ev_terjadi_plain_idx', pg_relation_size('lab6.ev_terjadi_plain_idx'));
SELECT pg_relation_size('lab6.ev_terjadi_plain_idx') AS bytes_polos,
       pg_relation_size('lab6.ev_gagal_idx')         AS bytes_parsial,
       pg_size_pretty(pg_relation_size('lab6.ev_terjadi_plain_idx')) AS polos,
       pg_size_pretty(pg_relation_size('lab6.ev_gagal_idx'))         AS parsial,
       round(100.0*(pg_relation_size('lab6.ev_terjadi_plain_idx')-pg_relation_size('lab6.ev_gagal_idx'))
             / pg_relation_size('lab6.ev_terjadi_plain_idx'), 2)    AS hemat_persen;
SELECT count(*) AS baris_gagal, round(100.0*count(*)/2000000,2) AS persen_baris
FROM lab6.event_log WHERE status='GAGAL';
