-- Diminta: membentangkan array kontak menjadi satu baris per kontak dengan tetap menampilkan notifikasi yang memiliki array kontak kosong.
-- Dipilih: jsonb_array_elements dengan LEFT JOIN LATERAL karena setiap elemen array dapat diubah menjadi satu baris, sementara LEFT JOIN mempertahankan notifikasi tanpa kontak.
-- Alternatif: CROSS JOIN LATERAL; tidak dipilih karena notifikasi dengan array kontak kosong tidak akan muncul.

SELECT
    n.payload ->> 'trx' AS nomor_transaksi,
    kontak ->> 'jenis' AS jenis_kontak,
    kontak ->> 'nomor' AS nomor_kontak
FROM notifikasi n
LEFT JOIN LATERAL
    jsonb_array_elements(n.payload -> 'kontak') AS kontak
ON true;