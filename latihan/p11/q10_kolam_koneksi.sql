-- Diminta: Menjelaskan dengan potongan kode bagaimana konteks penyewa bisa tertinggal di kolam koneksi dan cara mencegahnya.
-- Dipilih: Menggunakan blok transaksi dengan SET LOCAL agar variabel sesi otomatis dibersihkan saat transaksi COMMIT/ROLLBACK.
-- Alternatif: Menggunakan SET global tanpa transaksi; tidak dipilih karena variabel sesi akan bertahan dan bocor ke permintaan klien berikutnya di dalam pool.

BEGIN;
  -- SET LOCAL hanya berlaku selama blok transaksi ini berlangsung.
  -- Begitu COMMIT atau ROLLBACK dijalankan, variabel sesi 'app.tenant' otomatis terhapus.
  SET LOCAL app.tenant = '1';
  SELECT count(*) FROM lab11.pelanggan;
COMMIT;