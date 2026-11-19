-- Diminta: tabel tujuh peran, hak masing-masing, dan penanda login.
-- Dipilih: query katalog sistem (pg_roles, pg_auth_members, has_table_privilege), agar data dari sistem, bukan tebakan.
-- Alternatif: menulis tabel dari ingatan; tidak dipilih karena bisa meleset dari kondisi nyata.
--- 1. Tujuh peran, atribut, dan kemampuan login
SELECT rolname, rolcanlogin AS bisa_login, rolsuper, rolbypassrls
FROM pg_roles
WHERE rolname = 'skema_owner' OR rolname LIKE 'app\_%'
ORDER BY rolcanlogin, rolname;

--- 2. Keanggotaan peran (anggota -> induk)
SELECT r.rolname AS anggota, m.rolname AS induk
FROM pg_auth_members am
JOIN pg_roles r ON r.oid = am.member
JOIN pg_roles m ON m.oid = am.roleid
WHERE r.rolname = 'skema_owner' OR r.rolname LIKE 'app\_%'
ORDER BY 1, 2;

--- 3. Hak nyata tiap peran pada tabel pelanggan, akun, transaksi
SELECT r AS peran,
  has_table_privilege(r,'lab11.pelanggan','SELECT') AS pel_sel,
  has_table_privilege(r,'lab11.pelanggan','INSERT') AS pel_ins,
  has_table_privilege(r,'lab11.pelanggan','UPDATE') AS pel_upd,
  has_table_privilege(r,'lab11.pelanggan','DELETE') AS pel_del,
  has_table_privilege(r,'lab11.akun','SELECT')      AS akun_sel,
  has_table_privilege(r,'lab11.transaksi','SELECT') AS trx_sel
FROM unnest(ARRAY['skema_owner','app_read','app_write','app_laporan','app_portal','app_analitik','app_auditor']) AS r;
