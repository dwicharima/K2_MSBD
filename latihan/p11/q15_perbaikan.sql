-- Diminta: mengubah pemanggilan di rentan.py agar memakai cari_aman yang berparameter, mengulang
--          payload yang sama, mengutip hasilnya, dan menjelaskan mengapa penyaringan karakter
--          tidak mencapai hasil yang sama.
-- Dipilih: query berparameter (nilai dikirim lewat saluran terpisah dari kerangka SQL), karena
--          ini menghapus sebab masalah, yaitu bercampurnya kode dengan data.
-- Alternatif: membuang/meloloskan karakter ' -- ; (blacklist); tidak dipilih karena menyaring
--             gejala, merusak masukan sah (O'Brien), dan gagal pada konteks tanpa kutip.

-- ===== Bagian A: dijalankan di kontainer lab11-web =====
--   docker exec -it lab11-web python /app/rentan.py --aman "Pelanggan 12"
--   docker exec -it lab11-web python /app/rentan.py --aman "zz' OR '1'='1"
--   docker exec -it lab11-web python /app/rentan.py --aman "zz' OR '1'='1' --"
--   docker exec -it lab11-web python /app/rentan.py --aman \
--        "zz' UNION SELECT id, nama_pengguna, peran_aplikasi FROM lab11.akun --"
-- Masukan sah yang memuat kutip (blacklist akan merusaknya):
--   docker exec -it lab11-web python /app/rentan.py "O'Brien"          # rentan: galat sintaks
--   docker exec -it lab11-web python /app/rentan.py --aman "O'Brien"   # aman: 0 baris, tanpa galat

-- ===== Bagian B: padanan sisi server (psql sebagai postgres) =====
-- Kerangka diurai SEKALI; nilai hanya mengisi $1 dan $2 dan tidak pernah diurai ulang.
PREPARE cari_aman(int, text) AS
  SELECT count(*) AS baris FROM (
    SELECT id, nama, kota FROM lab11.pelanggan
    WHERE tenant_id = $1 AND nama ILIKE $2 LIMIT 100) s;

EXECUTE cari_aman(1, '%zz'' OR ''1''=''1'' --%');          -- harapan: 0 baris
EXECUTE cari_aman(1, '%zz'' OR ''1''=''1%');               -- harapan: 0 baris
EXECUTE cari_aman(1, '%Pelanggan 12%');                    -- tetap berfungsi (dibatasi LIMIT 100)
DEALLOCATE cari_aman;

-- Mengapa penyaringan karakter tidak setara: konteks numerik tidak memakai kutip sama sekali.
-- Filter yang membuang ' tetap meloloskan masukan   0 OR 1=1   (harapan: 30000).
SELECT count(*) AS lolos_filter_kutip FROM lab11.pelanggan WHERE tenant_id = 1 AND id = 0 OR 1=1;
