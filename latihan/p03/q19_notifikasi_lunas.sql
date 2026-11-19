-- Diminta: menampilkan seluruh notifikasi berstatus lunas beserta nomor transaksi, kota pelanggan, dan jumlah sebagai angka, serta menambahkan indeks GIN pada data JSONB.
-- Dipilih: operator @> untuk menyaring notifikasi berstatus lunas dan ->> untuk mengambil nilai JSONB sebagai teks sebelum jumlah diubah menjadi angka.
-- Alternatif: menggunakan ->> untuk menyaring status; tidak dipilih karena @> lebih sesuai untuk memeriksa apakah JSONB mengandung pasangan key dan nilai tertentu.

CREATE INDEX IF NOT EXISTS idx_notifikasi_payload_gin
ON notifikasi
USING GIN (payload);

SELECT
    payload ->> 'trx' AS nomor_transaksi,
    payload -> 'pelanggan' ->> 'kota' AS kota_pelanggan,
    (payload ->> 'jumlah')::numeric AS jumlah
FROM notifikasi
WHERE payload @> '{"status": "lunas"}';

\d notifikasi