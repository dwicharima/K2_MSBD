CREATE TABLE lab6.event_log_noidx
(LIKE lab6.event_log INCLUDING DEFAULTS);

\timing on

INSERT INTO lab6.event_log_noidx
(customer_id, terjadi_pada, status, wilayah, kota, email,
 idempotency_key, jumlah, tags, payload)
SELECT
    (random()*59999)::int+1,
    now(),
    'SUKSES',
    'SUMUT',
    'MEDAN',
    'test'||g||'@contoh.ac.id',
    gen_random_uuid(),
    round((random()*900+10)::numeric,2),
    ARRAY['kanal:1'],
    '{}'::jsonb
FROM generate_series(1,200000) AS s(g);