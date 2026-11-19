-- Diminta: Menghitung baris yang dilihat skema_owner sebelum dan sesudah FORCE RLS, serta menguji peran dengan pg_read_all_data dan BYPASSRLS.
-- Dipilih: Menerapkan ALTER TABLE ... FORCE ROW LEVEL SECURITY dan menguji hak akses peran khusus.
-- Alternatif: Membiarkan pemilik skema selalu bypass; tidak dipilih karena melanggar isolasi ketat jika pemilik melakukan kueri operasional.

-- 1. Sebelum FORCE RLS (Pemilik skema/tabel secara default melewati RLS):
SELECT count(*) AS owner_sebelum_force FROM lab11.pelanggan;

-- 2. Aktifkan FORCE RLS agar pemilik skema juga tunduk pada RLS (kecuali superuser):
ALTER TABLE lab11.pelanggan FORCE ROW LEVEL SECURITY;

-- Coba kueri sebagai skema_owner (akan bernilai 0 jika app.tenant belum diset):
SET ROLE skema_owner;
SELECT count(*) AS owner_setelah_force FROM lab11.pelanggan;
RESET ROLE;

-- 3. Beri app_analitik peran pg_read_all_data:
GRANT pg_read_all_data TO app_analitik;

SET ROLE app_analitik;
SET LOCAL app.tenant = '1';
SELECT count(*) AS analitik_baca_semua FROM lab11.pelanggan; -- Perhatikan apakah RLS diabaikan
RESET ROLE;

