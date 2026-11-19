CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
DECLARE
  t0 timestamptz; t1 timestamptz;
  n_bf int := 30;
  n_md5 int := 200000; 
  ms_bf6 numeric; ms_bf10 numeric; ms_md5 numeric;
  i int; x text;
BEGIN
  t0 := clock_timestamp();
  FOR i IN 1..n_bf LOOP x := crypt('rahasia123', gen_salt('bf', 6)); END LOOP;
  t1 := clock_timestamp();
  ms_bf6 := extract(epoch FROM (t1 - t0)) * 1000 / n_bf;

  t0 := clock_timestamp();
  FOR i IN 1..n_bf LOOP x := crypt('rahasia123', gen_salt('bf', 10)); END LOOP;
  t1 := clock_timestamp();
  ms_bf10 := extract(epoch FROM (t1 - t0)) * 1000 / n_bf;

  t0 := clock_timestamp();
  FOR i IN 1..n_md5 LOOP x := md5('rahasia123' || i::text); END LOOP;
  t1 := clock_timestamp();
  ms_md5 := extract(epoch FROM (t1 - t0)) * 1000 / n_md5;

  RAISE NOTICE 'bf cost 6  : % ms per hash', round(ms_bf6, 3);
  RAISE NOTICE 'bf cost 10 : % ms per hash', round(ms_bf10, 3);
  RAISE NOTICE 'md5        : % ms per hash', round(ms_md5, 6);
  RAISE NOTICE 'rasio bf10 / bf6  : % x (harapan ~16x, karena 2^(10-6))', round(ms_bf10 / ms_bf6, 1);
  RAISE NOTICE 'rasio bf10 / md5  : % x', round(ms_bf10 / ms_md5, 0);
  RAISE NOTICE 'tebakan/detik satu inti: bf10 = %, md5 = %', round(1000 / ms_bf10), round(1000 / ms_md5);
END $$;

