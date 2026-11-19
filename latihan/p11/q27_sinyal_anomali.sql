-- Diminta: mendeteksi lonjakan baris per peran.
-- Dipilih: menghitung aktivitas audit per pelaku.
-- Alternatif: hanya menghitung total seluruh aktivitas; tidak dipilih karena tidak menunjukkan pelakunya.

SELECT
    pelaku,
    COUNT(*) AS jumlah_perubahan
FROM lab11.jejak_audit
GROUP BY pelaku
ORDER BY jumlah_perubahan DESC;

-- Diminta: mendeteksi akses di luar jam kerja.
-- Dipilih: mengubah waktu audit ke zona Asia/Jakarta.
-- Alternatif: memakai waktu server tanpa zona waktu; tidak dipilih agar konsisten dengan WIB.

SELECT
    id,
    waktu,
    pelaku,
    aksi,
    nama_tabel,
    waktu AT TIME ZONE 'Asia/Jakarta' AS waktu_wib
FROM lab11.jejak_audit
WHERE
    EXTRACT(
        HOUR FROM waktu AT TIME ZONE 'Asia/Jakarta'
    ) < 8
    OR
    EXTRACT(
        HOUR FROM waktu AT TIME ZONE 'Asia/Jakarta'
    ) >= 17
ORDER BY waktu DESC;

-- Diminta: membuat ringkasan aksi.
-- Dipilih: menghitung jumlah setiap jenis aksi.
-- Alternatif: menampilkan semua baris audit; tidak dipilih karena kurang ringkas.

SELECT
    aksi,
    COUNT(*) AS jumlah_aktivitas
FROM lab11.jejak_audit
GROUP BY aksi
ORDER BY jumlah_aktivitas DESC;