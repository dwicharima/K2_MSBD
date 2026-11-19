-- Diminta: membuat laporan_kota_rentan dan laporan_kota_aman, menyimpan satu nilai status yang
--          berbahaya lewat jalur INSERT yang aman, memanggil kedua fungsi, membandingkan
--          hasilnya, dan menjelaskan mengapa pertahanan di pintu masuk tidak menolong.
-- Dipilih: kedua fungsi SECURITY INVOKER (tunduk RLS pemanggil) dan dijalankan dalam transaksi
--          yang di-ROLLBACK, sehingga baris uji tidak tertinggal dan penyewa lain tak tersentuh.
--          Perbaikan ditaruh di titik PEMAKAIAN nilai (EXECUTE ... USING), bukan di titik masuk.
-- Alternatif: membersihkan/menolak karakter berbahaya saat INSERT; tidak dipilih karena nilai
--             yang tersimpan sudah murni data, dan baru menjadi kode saat dirakit ulang
--             (second-order). Filter di pintu masuk tidak tahu konteks pemakaian di masa depan.

-- ===== Bagian A: buat dua fungsi (dijalankan sebagai postgres, dimiliki skema_owner) =====
SET ROLE skema_owner;

-- RENTAN: status hasil bacaan dari tabel dianggap "tepercaya" lalu ditempel ke SQL dinamis.
CREATE OR REPLACE FUNCTION lab11.laporan_kota_rentan(p_pelanggan_id int)
RETURNS TABLE (kota_hasil text, status_hasil text, jumlah bigint)
LANGUAGE plpgsql SECURITY INVOKER AS $$
DECLARE
  v_kota text; v_status text; q text;
BEGIN
  SELECT p.kota, p.status INTO v_kota, v_status
  FROM lab11.pelanggan p WHERE p.id = p_pelanggan_id;

  q := 'SELECT kota, status, count(*) FROM lab11.pelanggan WHERE kota = '
       || quote_literal(v_kota)
       || ' AND status = ''' || v_status || ''''      -- <-- status ditempel mentah
       || ' GROUP BY kota, status ORDER BY kota';
  RETURN QUERY EXECUTE q;
END $$;

-- AMAN: nilai dikirim lewat USING, tidak pernah menjadi bagian kode.
CREATE OR REPLACE FUNCTION lab11.laporan_kota_aman(p_pelanggan_id int)
RETURNS TABLE (kota_hasil text, status_hasil text, jumlah bigint)
LANGUAGE plpgsql SECURITY INVOKER AS $$
DECLARE
  v_kota text; v_status text;
BEGIN
  SELECT p.kota, p.status INTO v_kota, v_status
  FROM lab11.pelanggan p WHERE p.id = p_pelanggan_id;

  RETURN QUERY EXECUTE
    'SELECT kota, status, count(*) FROM lab11.pelanggan
      WHERE kota = $1 AND status = $2 GROUP BY kota, status ORDER BY kota'
    USING v_kota, v_status;
END $$;
RESET ROLE;

-- ===== Bagian B: simpan nilai berbahaya lewat INSERT yang aman, lalu pakai ulang =====
-- Nilai status:   AKTIF' OR '1'='1   (hanya membaca). Dua kutipnya dilindungi dolar-quote,
-- setara dengan parameter %s pada Python: disimpan apa adanya sebagai DATA.
BEGIN;
SET LOCAL app.tenant = '1';

-- B1. INSERT oleh app_portal (peran tulis penyewa 1; tunduk WITH CHECK kebijakan)
SET LOCAL ROLE app_portal;
INSERT INTO lab11.pelanggan (tenant_id, nama, kota, status)
VALUES (1, 'Uji Second Order', 'Medan', $v$AKTIF' OR '1'='1$v$)
RETURNING id AS id_uji, status AS status_tersimpan \gset
\echo id_uji = :id_uji

-- B2. Panggil kedua fungsi sebagai app_laporan (peran baca penyewa 1)
RESET ROLE;
SET LOCAL ROLE app_laporan;
SELECT current_user AS peran_aktif;
SELECT 'rentan' AS fungsi, * FROM lab11.laporan_kota_rentan(:id_uji);
SELECT 'aman'   AS fungsi, * FROM lab11.laporan_kota_aman(:id_uji);
ROLLBACK;

-- B3. Pastikan baris uji tidak tertinggal (harapan: 10000 untuk penyewa 1)
SELECT count(*) AS pelanggan_tenant1 FROM lab11.pelanggan WHERE tenant_id = 1;

-- ===== Bagian C: jalur aplikasi (kontainer lab11-web, peran app_portal) =====
--   docker exec -it lab11-web python /app/rentan.py --second-order
