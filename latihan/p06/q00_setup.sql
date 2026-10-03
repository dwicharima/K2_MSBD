CREATE SCHEMA IF NOT EXISTS lab6;
CREATE TABLE lab6.event_log (
  event_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  customer_id integer NOT NULL, terjadi_pada timestamptz NOT NULL,
  status text NOT NULL, wilayah text NOT NULL, kota text NOT NULL,
  email text NOT NULL, idempotency_key uuid NOT NULL,
  jumlah numeric(10,2) NOT NULL, tags text[] NOT NULL DEFAULT '{}',
  payload jsonb NOT NULL DEFAULT '{}'::jsonb
);
INSERT INTO lab6.event_log
(customer_id,terjadi_pada,status,wilayah,kota,email,idempotency_key,jumlah,tags,payload)
SELECT (random()*59999)::int+1,
  timestamptz '2024-01-01 00:00+07'+(g*interval '13 second'),
  CASE WHEN g%50=0 THEN 'GAGAL' WHEN g%7=0 THEN 'TERTUNDA' ELSE 'SUKSES' END,
  w.nama,w.nama||'-'||((g%9)+1),'user'||g||'@contoh.ac.id',gen_random_uuid(),
  round((random()*900+10)::numeric,2),ARRAY['kanal:'||(g%4),'sumber:'||(g%3)],
  jsonb_build_object('kanal',g%4,'perangkat',g%6,'promo',(g%25=0))
FROM generate_series(1,2000000) AS s(g)
CROSS JOIN LATERAL (SELECT (ARRAY['SUMUT','JABAR','JATIM','BALI','PAPUA'])[(g%5)+1] AS nama) AS w;
ANALYZE lab6.event_log;