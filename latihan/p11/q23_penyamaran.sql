REVOKE pg_read_all_data FROM app_analitik;
CREATE OR REPLACE VIEW lab11.v_pelanggan_samar WITH (security_barrier = true) AS
SELECT id, tenant_id,
       left(nama,1) || repeat('*', greatest(length(nama)-1, 1))  AS nama,
       'xxxxxxxxxxxx' || right(nik, 4)                           AS nik,
       regexp_replace(surel, '^[^@]+', '****')                   AS surel,
       date_trunc('year', lahir)::date                           AS lahir_tahun,
       kota, round(saldo, -5)                                    AS saldo_bulat
FROM lab11.pelanggan;
REVOKE ALL   ON lab11.pelanggan         FROM app_analitik;
GRANT  SELECT ON lab11.v_pelanggan_samar TO   app_analitik;

SELECT pg_has_role('app_analitik', 'pg_read_all_data', 'member') AS anggota_read_all;

BEGIN;
SET LOCAL ROLE app_analitik;
SELECT current_user AS peran_aktif;
SELECT count(*) FROM lab11.pelanggan; 
ROLLBACK;

BEGIN;
SET LOCAL ROLE app_analitik;
SELECT id, tenant_id, nama, nik, surel, lahir_tahun, kota, saldo_bulat
FROM lab11.v_pelanggan_samar ORDER BY id LIMIT 5;
SELECT count(*) AS baris_lewat_view FROM lab11.v_pelanggan_samar;
SELECT has_table_privilege('app_analitik', 'lab11.pelanggan', 'SELECT')          AS hak_tabel_asli, 
       has_table_privilege('app_analitik', 'lab11.v_pelanggan_samar', 'SELECT')  AS hak_view;  
COMMIT;

BEGIN;
CREATE VIEW lab11.v_uji_invoker WITH (security_invoker = true) AS SELECT id, kota FROM lab11.pelanggan;
GRANT SELECT ON lab11.v_uji_invoker TO app_analitik;
SET LOCAL ROLE app_analitik;
SELECT count(*) FROM lab11.v_uji_invoker;
ROLLBACK;
