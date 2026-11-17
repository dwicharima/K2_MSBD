-- Diminta: memeriksa apakah tabel buatan postgres otomatis terbaca app_laporan.
-- Dipilih: has_table_privilege, supaya terbukti tanpa mengubah data.
-- Alternatif: SELECT langsung sebagai app_laporan; hasilnya sama tapi lebih berantakan.
--- Dijalankan sebagai postgres
SELECT current_user AS peran_aktif;
CREATE TABLE lab11.catatan_postgres (id int);
SELECT has_table_privilege('app_laporan','lab11.catatan_postgres','SELECT') AS via_postgres;
DROP TABLE lab11.catatan_postgres;
--- Pembanding: tabel buatan skema_owner
SET ROLE skema_owner;
CREATE TABLE lab11.catatan_owner (id int);
SELECT has_table_privilege('app_laporan','lab11.catatan_owner','SELECT') AS via_skema_owner;
DROP TABLE lab11.catatan_owner;
RESET ROLE;
