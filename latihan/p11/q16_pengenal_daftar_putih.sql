-- Diminta: menunjukkan satu bagian query yang tidak bisa diparameterkan (nama kolom atau arah
--          urut), menanganinya dengan daftar putih tertutup, dan membuktikan nilai di luar
--          daftar ditolak.
-- Dipilih: kamus tertutup KOLOM dan ARAH; yang masuk ke SQL adalah nilai kamus milik kita,
--          bukan masukan pengguna.
-- Alternatif: meloloskan nama kolom dengan quote_ident()/%I atau regex huruf-angka; tidak
--             dipilih karena hanya menjamin bentuk yang valid, bukan bahwa kolom itu boleh
--             dipakai pengguna (misalnya kolom nik atau saldo).

-- ===== Bagian A: dijalankan di kontainer lab11-web =====
--   docker exec -it lab11-web python /app/rentan.py --urut kota --arah turun "Pelanggan 12"
--   docker exec -it lab11-web python /app/rentan.py --urut terbaru --arah naik "Pelanggan 12"
--   # di luar daftar -> ditolak sebelum menyentuh basis data:
--   docker exec -it lab11-web python /app/rentan.py --urut "nama; DROP TABLE lab11.akun" "Pelanggan 12"
--   docker exec -it lab11-web python /app/rentan.py --urut nama --arah "ASC; SELECT pg_sleep(9)" "Pelanggan 12"
--   docker exec -it lab11-web python /app/rentan.py --urut nik "Pelanggan 12"      # nik tidak ada di daftar

-- ===== Bagian B: bukti bahwa kolom dan arah tidak bisa menjadi parameter =====
-- B1. Parameter pada ORDER BY dianggap NILAI KONSTAN, bukan nama kolom: urutan tidak berubah.
PREPARE urut_param(text) AS
  SELECT id, nama, kota FROM lab11.pelanggan WHERE id IN (12,120,121) ORDER BY $1;
EXECUTE urut_param('kota');
DEALLOCATE urut_param;
-- B2. Arah urut sebagai parameter bahkan tidak lolos tahap penguraian (harapan: syntax error).
PREPARE urut_arah(text) AS
  SELECT id, nama FROM lab11.pelanggan WHERE id IN (12,120,121) ORDER BY nama $1;

-- ===== Bagian C: daftar putih yang sama di sisi SQL (DO block, harapan: lolos lalu ditolak) =====
DO $$
DECLARE
  kolom text; arah text; uji text[][] := ARRAY[['kota','turun'],['terbaru','naik'],
      ['nama; DROP TABLE lab11.akun','naik'],['nama','ASC; SELECT pg_sleep(9)'],['nik','naik']];
  i int;
BEGIN
  FOR i IN 1..array_length(uji,1) LOOP
    kolom := uji[i][1]; arah := uji[i][2];
    IF kolom NOT IN ('nama','kota','terbaru') OR arah NOT IN ('naik','turun') THEN
      RAISE NOTICE 'DITOLAK  kolom=% arah=% : parameter pengurutan tidak dikenal', kolom, arah;
    ELSE
      RAISE NOTICE 'DITERIMA kolom=% arah=%', kolom, arah;
    END IF;
  END LOOP;
END $$;
