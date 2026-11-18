-- Diminta: Menyalakan RLS pada tabel pelanggan dan menghitung baris yang terlihat oleh app_laporan sebelum ada kebijakan.
-- Dipilih: Menggunakan ALTER TABLE ... ENABLE ROW LEVEL SECURITY diikuti pengujian dengan SET LOCAL ROLE.
-- Alternatif: Langsung membuat kebijakan; tidak dipilih karena tujuannya membuktikan perilaku default deny RLS.

ALTER TABLE lab11.pelanggan ENABLE ROW LEVEL SECURITY;

BEGIN; 
SET LOCAL ROLE app_laporan;
  SELECT count(*) AS sebelum_ada_kebijakan FROM lab11.pelanggan;   -- harapkan 0
COMMIT;
