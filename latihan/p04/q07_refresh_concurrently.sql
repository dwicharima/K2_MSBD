-- Diminta: mencoba refresh materialized view secara concurrent, mencatat
-- pesan galat, membuat unique index yang mencakup seluruh baris matview,
-- kemudian mengulangi refresh concurrent dan mencatat waktunya.

-- Dipilih: unique index pada (bulan, kanal) karena kombinasi tersebut
-- mengidentifikasi setiap baris hasil GROUP BY pada materialized view.
-- REFRESH CONCURRENTLY dipilih untuk memungkinkan pembaca tetap mengakses
-- materialized view selama proses refresh.

-- Alternatif: menggunakan REFRESH MATERIALIZED VIEW biasa saja; tidak dipilih
-- karena refresh biasa dapat memblokir pembaca dan tidak menguji tujuan
-- utama penggunaan CONCURRENTLY.

\timing on

-- Percobaan pertama: seharusnya gagal karena belum ada unique index.
REFRESH MATERIALIZED VIEW CONCURRENTLY lab4.ringkasan_akses;

-- Membuat unique index untuk memenuhi syarat refresh concurrent.
CREATE UNIQUE INDEX ringkasan_akses_bulan_kanal_uidx
ON lab4.ringkasan_akses (bulan, kanal);

-- Percobaan kedua: refresh concurrent setelah unique index dibuat.
REFRESH MATERIALIZED VIEW CONCURRENTLY lab4.ringkasan_akses;