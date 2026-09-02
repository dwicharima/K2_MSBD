UPDATE tim t
SET nim_ketua = m.nim
FROM mahasiswa m
WHERE t.nama_ketua = m.nama_mahasiswa
    AND t.nim_ketua IS NULL;