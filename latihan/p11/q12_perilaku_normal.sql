-- Diminta: menjalankan rentan.py dengan satu nama biasa sebagai pembanding, menyalin teks SQL
--          yang tercetak, dan menunjukkan bagian mana yang berasal dari masukan pengguna.
-- Dipilih: membuat garis dasar (baseline) dengan masukan biasa sebelum menyerang, supaya
--          selisih pada Q13-Q15 bisa diukur terhadap angka yang sama.
-- Alternatif: langsung memakai payload serangan; tidak dipilih karena tanpa pembanding kita
--             tidak bisa membuktikan apa yang berubah akibat masukan.

-- ===== Bagian A: dijalankan di kontainer lab11-web (peran koneksi: postgres) =====
--   docker exec -it lab11-web python /app/rentan.py "Pelanggan 12"
--
-- Teks SQL yang tercetak (bagian masukan pengguna ditandai <<...>>):
--   SELECT id, nama, kota FROM lab11.pelanggan
--   WHERE tenant_id = 1 AND nama ILIKE '%<<Pelanggan 12>>%'
--
-- Bagian TETAP (milik programmer) : SELECT id, nama, kota FROM lab11.pelanggan
--                                   WHERE tenant_id = 1 AND nama ILIKE '%  ...  %'
-- Bagian dari MASUKAN (milik user) : Pelanggan 12
-- Masalahnya: keduanya digabung menjadi satu string, lalu server mengurainya sebagai satu
-- kalimat SQL. Server tidak punya cara tahu di mana kode berhenti dan data mulai.

-- ===== Bagian B: padanan murni SQL (dijalankan lewat psql sebagai postgres) =====
-- Teks yang sama persis dengan yang tercetak oleh Python:
SELECT current_user AS peran_aktif;
SELECT count(*) AS baris_pelanggan_12_tenant1
FROM lab11.pelanggan WHERE tenant_id = 1 AND nama ILIKE '%Pelanggan 12%';
