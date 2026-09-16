-- Diminta: Menghapus mekanisme trigger tulis ganda.
-- Dipilih: Menggunakan DROP TRIGGER dan DROP FUNCTION secara berurutan.
-- Alternatif: Melumpuhkan trigger (DISABLE); tidak dipilih karena rollback harus membersihkan objek yang dibuat.

DROP TRIGGER IF EXISTS trg_tulis_ganda_harga ON lab4.film;
DROP FUNCTION IF EXISTS lab4.sync_tulis_ganda_harga();