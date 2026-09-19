-- Diminta: Menghapus data hasil penyalinan backfill dari tabel harga_film.
-- Dipilih: DELETE spesifik berdasarkan wilayah 'ID' yang diisi pada proses up.sql.
-- Alternatif: TRUNCATE tabel; tidak dipilih karena akan menghapus data sah lain jika ada.

DELETE FROM lab4.harga_film WHERE wilayah = 'ID';