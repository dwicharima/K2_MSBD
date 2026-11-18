-- Diminta: mengulang payload yang sama lewat koneksi app_laporan (anggota app_read, tunduk
--          kebijakan penyewa), mencatat apa yang berubah dan apa yang tetap, lalu
--          mengaitkannya dengan prinsip hak minimum per tabel.
-- Dipilih: membandingkan jumlah baris postgres vs app_laporan, lalu menguji pencabutan
--          SELECT pada tabel akun di dalam transaksi yang di-ROLLBACK, supaya peran milik
--          anggota lain tidak berubah permanen.
-- Alternatif: langsung REVOKE permanen pada akun; tidak dipilih karena mengubah keadaan
--             bersama kelompok dan tabel tujuh peran (Q5) milik anggota lain.

-- ===== Bagian A: dijalankan di kontainer lab11-web =====
--   docker exec -it lab11-web python /app/rentan.py --user app_laporan "Pelanggan 12"
--   docker exec -it lab11-web python /app/rentan.py --user app_laporan "zz' OR '1'='1' --"
--   docker exec -it lab11-web python /app/rentan.py --user app_laporan \
--        "zz' UNION SELECT id, nama_pengguna, peran_aplikasi FROM lab11.akun --"
-- (bandingkan dengan Q13: postgres menghasilkan 30000 baris)

-- ===== Bagian B: padanan SQL (psql sebagai postgres) =====
-- B1. Payload 2 sebagai app_laporan penyewa 1 (harapan: 10000, bukan 30000)
BEGIN;
SET LOCAL ROLE app_laporan;
SET LOCAL app.tenant = '1';
SELECT current_user AS peran_aktif;
SELECT count(*) AS payload2_app_laporan FROM lab11.pelanggan
WHERE tenant_id = 1 AND nama ILIKE '%zz' OR '1'='1' --%'
;
-- B2. Baris penyewa lain yang terlihat (harapan: 0)
SELECT count(*) AS baris_tenant2_3 FROM lab11.pelanggan
WHERE tenant_id = 1 AND nama ILIKE '%zz' OR '1'='1' --%'
  AND tenant_id <> 1;
COMMIT;

-- B3. Yang TETAP: app_laporan masih bisa membaca tabel lain lewat UNION (read-only)
SELECT has_table_privilege('app_laporan','lab11.akun','SELECT') AS boleh_baca_akun;
BEGIN;
SET LOCAL ROLE app_laporan;
SET LOCAL app.tenant = '1';
SELECT id, nama, kota FROM lab11.pelanggan
WHERE tenant_id = 1 AND nama ILIKE '%zz'
UNION SELECT id, nama_pengguna, peran_aplikasi FROM lab11.akun --%'
;
COMMIT;

-- B4. Hak minimum per tabel: cabut SELECT pada akun dari app_read (HANYA di dalam transaksi)
BEGIN;
REVOKE SELECT ON lab11.akun FROM app_read;
SELECT has_table_privilege('app_laporan','lab11.akun','SELECT') AS boleh_baca_akun_setelah_revoke;
SET LOCAL ROLE app_laporan;
SET LOCAL app.tenant = '1';
SELECT id, nama, kota FROM lab11.pelanggan
WHERE tenant_id = 1 AND nama ILIKE '%zz'
UNION SELECT id, nama_pengguna, peran_aplikasi FROM lab11.akun --%'
;   -- harapan: ERROR permission denied for table akun
ROLLBACK;
-- B5. Pastikan keadaan bersama tidak berubah (harapan: t)
SELECT has_table_privilege('app_laporan','lab11.akun','SELECT') AS pulih;
