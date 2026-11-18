-- Diminta: Menguji visibilitas data sebagai app_laporan untuk tenant 1 dan memastikan tenant 2 bernilai nol.
-- Dipilih: Menggunakan SET LOCAL ROLE dan SET LOCAL app.tenant di dalam blok transaksi terisolasi.
-- Alternatif: Mengubah konfigurasi global tanpa transaksi; tidak dipilih karena dapat mencemari sesi koneksi berikutnya.

BEGIN; 
SET LOCAL ROLE app_laporan; 
SET LOCAL app.tenant = '1';
  SELECT count(*) AS terlihat_tenant1 FROM lab11.pelanggan;        -- harapkan 10000
  SELECT count(*) AS harus_nol FROM lab11.pelanggan WHERE tenant_id = 2;  -- harapkan 0
COMMIT;