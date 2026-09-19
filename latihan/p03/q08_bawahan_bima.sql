-- Diminta: menampilkan semua bawahan langsung maupun tidak langsung dari pegawai
--          bernama Bima, beserta jaraknya (jumlah tingkat) dari Bima.
-- Dipilih: recursive CTE dengan anchor disaring langsung pada nama = 'Bima' (jarak 0),
--          lalu recursive term mencari pegawai yang atasan_id-nya sama dengan
--          pegawai_id yang sudah masuk pada iterasi sebelumnya, sambil menambah jarak.
-- Alternatif: memakai hasil Q7 (hierarki seluruh pegawai) lalu menyaring baris yang
--          jalurnya mengandung 'Bima' di lapisan luar; tidak dipilih karena pencarian
--          teks pada jalur rawan salah tangkap bila ada nama pegawai yang mirip/berulang,
--          sedangkan menyaring anchor sejak awal lebih aman dan lebih cepat.

WITH RECURSIVE bawahan AS (
    -- anchor: Bima sendiri, jarak 0
    SELECT pegawai_id, nama, atasan_id, 0 AS jarak
    FROM pegawai
    WHERE nama = 'Bima'

    UNION ALL

    -- recursive term: bawahan langsung dari baris yang baru ditemukan (b)
    SELECT p.pegawai_id, p.nama, p.atasan_id, b.jarak + 1
    FROM pegawai p
    JOIN bawahan b ON p.atasan_id = b.pegawai_id
)
SELECT pegawai_id, nama, jarak
FROM bawahan
WHERE jarak > 0   -- Bima sendiri tidak termasuk "bawahan"
ORDER BY jarak, nama;
