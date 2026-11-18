-- Diminta: Menyebutkan tiga cara isolasi RLS bisa gagal beserta perbaikannya, dan membuktikan minimal satu.
-- Dipilih: Mendemonstrasikan celah fungsi SECURITY DEFINER / bypass pemilik.
-- Alternatif: Celah kueri fungsi agregat tanpa filter; tidak dipilih karena fokus pada pembuktian fungsi istimewa.

/*
Tiga Celah Isolasi RLS dan Perbaikannya:
1. Penggunaan Fungsi SECURITY DEFINER: Fungsi yang berjalan dengan hak istimewa pembuatnya (misal superuser/owner) dapat mem-bypass RLS. 
   - Perbaikan: Gunakan SECURITY INVOKER agar fungsi berjalan dengan hak pemanggil yang dibatasi RLS.
2. Akses oleh Superuser atau Peran beratribut BYPASSRLS: Akun administratif mengabaikan aturan RLS.
   - Perbaikan: Batasi akses superuser dan pastikan aplikasi tidak pernah berjalan di atas akun administratif.
3. Kebijakan yang Kurang Ketat pada Perintah UPDATE/DELETE (Kurangnya klausul WITH CHECK): Memungkinkan pengguna memindahkan baris ke tenant lain.
   - Perbaikan: Selalu tetapkan klausul WITH CHECK yang menyamakan validasi dengan USING pada kebijakan RLS.
*/

-- Bukti Celah Fungsi SECURITY DEFINER:
CREATE OR REPLACE FUNCTION lab11.bocor_data() 
RETURNS TABLE (id int, nama text, t_id int) 
SECURITY DEFINER -- Menjalankan fungsi dengan hak istimewa pembuat (owner/superuser)
AS $$
  SELECT id, nama, tenant_id FROM lab11.pelanggan;
$$ LANGUAGE sql;

-- Uji sebagai app_laporan (yang seharusnya dibatasi RLS):
BEGIN;
SET LOCAL ROLE app_laporan;
  -- Fungsi SECURITY DEFINER membobol RLS dan menampilkan seluruh data lintas penyewa:
  SELECT count(*) AS total_bocor_lintas_tenant FROM lab11.bocor_data();
COMMIT;

DROP FUNCTION lab11.bocor_data();