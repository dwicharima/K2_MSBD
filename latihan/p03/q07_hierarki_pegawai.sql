-- Diminta: menampilkan seluruh pegawai beserta level kedalaman dan jalur jabatan
--          dari puncak, misalnya Rina > Bima > Toni.
-- Dipilih: recursive CTE dengan anchor pegawai yang atasan_id IS NULL (pucuk hierarki),
--          lalu recursive term menyambungkan setiap bawahan langsung ke baris induknya
--          yang sudah terbentuk pada iterasi sebelumnya, sambil menambah level dan
--          merangkai jalur teks dengan ' > '.
-- Alternatif: query berulang manual per level (self-join bertingkat sebanyak kedalaman
--          maksimum); tidak dipilih karena jumlah level tidak diketahui di awal dan
--          recursive CTE otomatis berhenti saat tidak ada bawahan lagi.

WITH RECURSIVE hierarki AS (
    -- anchor: pucuk hierarki
    SELECT pegawai_id,
           nama,
           atasan_id,
           1 AS level,
           nama::text AS jalur
    FROM pegawai
    WHERE atasan_id IS NULL

    UNION ALL

    -- recursive term: hanya melihat baris yang baru terbentuk di iterasi sebelumnya (h)
    SELECT p.pegawai_id,
           p.nama,
           p.atasan_id,
           h.level + 1,
           h.jalur || ' > ' || p.nama
    FROM pegawai p
    JOIN hierarki h ON p.atasan_id = h.pegawai_id
)
SELECT pegawai_id, nama, level, jalur
FROM hierarki
ORDER BY jalur;
