-- Diminta: GRANT OPTION ke app_write, diteruskan ke app_analitik, lalu dicabut tanpa dan dengan CASCADE.
-- Dipilih: REVOKE GRANT OPTION FOR, supaya hanya hak meneruskan yang dicabut, bukan SELECT-nya.
-- Alternatif: REVOKE SELECT ... CASCADE; tidak dipilih karena mencabut SELECT app_write seluruhnya.
--- 1. Beri app_write SELECT WITH GRANT OPTION (sebagai postgres)
GRANT SELECT ON lab11.transaksi TO app_write WITH GRANT OPTION;
--- 2. app_write meneruskan SELECT ke app_analitik
SET ROLE app_write;
SELECT current_user AS peran_aktif;
GRANT SELECT ON lab11.transaksi TO app_analitik;
RESET ROLE;
--- 3. Sebelum dicabut
SELECT has_table_privilege('app_analitik','lab11.transaksi','SELECT') AS analitik,
       has_table_privilege('app_write','lab11.transaksi','SELECT')    AS app_write;
--- 4. REVOKE GRANT OPTION tanpa CASCADE (harapan galat dependent privileges exist)
REVOKE GRANT OPTION FOR SELECT ON lab11.transaksi FROM app_write;
--- 5. REVOKE GRANT OPTION dengan CASCADE
REVOKE GRANT OPTION FOR SELECT ON lab11.transaksi FROM app_write CASCADE;
--- 6. Sesudah dicabut (harapkan analitik = f, app_write = t)
SELECT has_table_privilege('app_analitik','lab11.transaksi','SELECT') AS analitik,
       has_table_privilege('app_write','lab11.transaksi','SELECT')    AS app_write;
--- 7. Bukti app_write masih bisa membaca (sebagai app_write)
SET ROLE app_write;
SELECT current_user AS peran_aktif, count(*) AS baris_transaksi FROM lab11.transaksi;
RESET ROLE;
