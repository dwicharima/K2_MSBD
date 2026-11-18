-- Diminta: Membuat sepasang kebijakan isolasi penyewa menggunakan nullif(current_setting('app.tenant', true), '')::int.
-- Dipilih: Menggunakan nullif agar string kosong ('') tidak memicu galat 'invalid input syntax for type integer' pada PostgreSQL.
-- Alternatif: Menggunakan casting langsung ::int; tidak dipilih karena rentan gagal saat koneksi dipakai ulang dengan nilai kosong.

CREATE POLICY p_tenant_baca ON lab11.pelanggan
  FOR SELECT TO app_laporan, app_write
  USING (tenant_id = nullif(current_setting('app.tenant', true), '')::int);

CREATE POLICY p_tenant_tulis ON lab11.pelanggan
  FOR ALL TO app_write
  USING      (tenant_id = nullif(current_setting('app.tenant', true), '')::int)
  WITH CHECK (tenant_id = nullif(current_setting('app.tenant', true), '')::int);