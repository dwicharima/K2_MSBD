\set ON_ERROR_STOP on
DROP SCHEMA IF EXISTS lab11 CASCADE;

DO $$
DECLARE r text;
BEGIN
  FOREACH r IN ARRAY ARRAY['skema_owner','app_read','app_write'] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r) THEN
      EXECUTE format('CREATE ROLE %I NOLOGIN', r);
    END IF;
  END LOOP;
  FOREACH r IN ARRAY ARRAY['app_laporan','app_portal','app_analitik','app_auditor'] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r) THEN
      EXECUTE format('CREATE ROLE %I LOGIN PASSWORD %L', r, 'lab11-pass');
    END IF;
  END LOOP;
END $$;

ALTER ROLE app_analitik NOBYPASSRLS;
REVOKE pg_read_all_data FROM app_analitik;
ALTER ROLE app_portal RESET statement_timeout;

GRANT app_read  TO app_laporan;
GRANT app_read  TO app_auditor;
GRANT app_write TO app_portal;

CREATE SCHEMA lab11 AUTHORIZATION skema_owner;
GRANT USAGE ON SCHEMA lab11 TO app_read, app_write, app_analitik;

ALTER DEFAULT PRIVILEGES FOR ROLE skema_owner IN SCHEMA lab11
  GRANT SELECT ON TABLES TO app_read;
ALTER DEFAULT PRIVILEGES FOR ROLE skema_owner IN SCHEMA lab11
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_write;
ALTER DEFAULT PRIVILEGES FOR ROLE skema_owner IN SCHEMA lab11
  GRANT USAGE, SELECT ON SEQUENCES TO app_write;

SET ROLE skema_owner;

CREATE TABLE lab11.tenant (
  id   serial PRIMARY KEY,
  nama text NOT NULL
);

CREATE TABLE lab11.pelanggan (
  id          serial PRIMARY KEY,
  tenant_id   int NOT NULL REFERENCES lab11.tenant(id),
  nama        text NOT NULL,
  nik         text,
  surel       text,
  lahir       date,
  kota        text,
  saldo       numeric(14,2),
  rekening    text,
  status      text NOT NULL DEFAULT 'AKTIF',
  dibuat_pada timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE lab11.akun (
  id             serial PRIMARY KEY,
  nama_pengguna  text UNIQUE NOT NULL,
  peran_aplikasi text
);

CREATE TABLE lab11.transaksi (
  id           serial PRIMARY KEY,
  tenant_id    int NOT NULL REFERENCES lab11.tenant(id),
  pelanggan_id int NOT NULL REFERENCES lab11.pelanggan(id),
  jumlah       numeric(14,2),
  waktu        timestamptz NOT NULL DEFAULT now()
);

INSERT INTO lab11.tenant (nama) VALUES ('Penyewa 1'), ('Penyewa 2'), ('Penyewa 3');

INSERT INTO lab11.akun (nama_pengguna, peran_aplikasi) VALUES
  ('sinta','operator'), ('bagas','penyelia'), ('ratna','operator'), ('yusuf','auditor');

INSERT INTO lab11.pelanggan
  (id, tenant_id, nama, nik, surel, lahir, kota, saldo, rekening, status, dibuat_pada)
SELECT g,
       (g - 1) / 10000 + 1,
       'Pelanggan ' || g,
       '1271' || lpad(g::text, 12, '0'),
       'pelanggan' || g || '@contoh.ac.id',
       DATE '1970-01-01' + ((g * 37) % 18000),
       (ARRAY['Medan','Jakarta','Bandung','Surabaya','Makassar'])[1 + g % 5],
       100000 + ((g::bigint * 104729) % 90000000) / 100.0,
       lpad(((g::bigint * 7919003) % 10000000000)::text, 10, '0'),
       'AKTIF',
       TIMESTAMPTZ '2024-01-01 08:00+07' + (g % 700) * interval '1 day'
FROM generate_series(1, 30000) g;
SELECT setval(pg_get_serial_sequence('lab11.pelanggan','id'), 30000);

INSERT INTO lab11.transaksi (tenant_id, pelanggan_id, jumlah, waktu)
SELECT p.tenant_id, p.id,
       10000 + ((p.id::bigint * 31 + t * 977) % 5000000) / 100.0,
       TIMESTAMPTZ '2025-01-01 09:00+07' + ((p.id + t) % 600) * interval '1 day'
FROM lab11.pelanggan p CROSS JOIN generate_series(1, 5) t
WHERE p.id % 5 <> 0;

CREATE INDEX ON lab11.pelanggan (tenant_id);
CREATE INDEX ON lab11.transaksi (pelanggan_id);

RESET ROLE;
ANALYZE;