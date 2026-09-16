-- Diminta: Membatalkan pembuatan tabel lab4.harga_film.
-- Dipilih: DROP TABLE CASCADE untuk menghapus tabel beserta constraint turunannya.
-- Alternatif: DELETE isi tabel; tidak dipilih karena rollback struktur harus mengembalikan skema ke kondisi awal.

DROP TABLE IF EXISTS lab4.harga_film CASCADE;