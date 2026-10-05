DROP INDEX lab6.ev_cover_idx;
CREATE INDEX ev_tiga_idx ON lab6.event_log (customer_id, terjadi_pada, jumlah);
ANALYZE lab6.event_log;
INSERT INTO lab6.p06_ukuran_index(label, bytes) VALUES ('ev_tiga_idx', pg_relation_size('lab6.ev_tiga_idx'));
SELECT label AS index, pg_size_pretty(bytes) AS ukuran, bytes
FROM (SELECT DISTINCT ON (label) label, bytes FROM lab6.p06_ukuran_index
      WHERE label IN ('ev_cover_idx','ev_tiga_idx') ORDER BY label, dicatat DESC) t ORDER BY label;
