-- Diminta: membuat siklus pada tabel pegawai, mengamati dampaknya pada query rekursif
--          hierarki (Q7/Q8), lalu memperbaiki query agar tahan siklus, dan mengembalikan
--          data ke keadaan semula setelah pengujian selesai.
-- Dipilih: jalur bertipe array int[] (jalur_id) yang dibawa di setiap baris CTE, dengan
--          syarat "WHERE NOT (p.pegawai_id = ANY(h.jalur_id))" pada recursive term,
--          sehingga pegawai yang sudah pernah dilewati pada jalur tersebut tidak lagi
--          diproses ulang -- siklus otomatis terputus tanpa perlu tahu di mana letaknya.
-- Alternatif: klausa bawaan "CYCLE pegawai_id SET is_cycle USING jalur_id" (PostgreSQL 16+);
--          tidak dipilih sebagai jawaban utama karena versi array manual lebih eksplisit
--          untuk dijelaskan langkah demi langkah, walau klausa CYCLE lebih ringkas dan
--          layak disebut sebagai alternatif yang setara.

-- ============================================================
-- 1) MEMBUAT SIKLUS (jalankan terpisah lebih dulu, satu baris saja)
--    Rina (1) jadi bawahan Vino (6), padahal Vino ada di bawah Toni -> Bima -> Rina.
--    Ini membentuk siklus tertutup: 1 -> 6 -> 4 -> 2 -> 1
-- ============================================================
-- UPDATE pegawai SET atasan_id = 6 WHERE pegawai_id = 1;

-- ============================================================
-- 2) AMATI: jalankan q07_hierarki_pegawai.sql apa adanya setelah UPDATE di atas.
--    Catatan hasil pengamatan (tulis versi kalian sendiri di laporan.md):
--    - Anchor Q7 mensyaratkan atasan_id IS NULL. Setelah UPDATE, tidak ada lagi
--      pegawai dengan atasan_id NULL, sehingga anchor kosong dan Q7 hanya
--      mengembalikan 0 baris -- bukan infinite loop, tapi hasil yang diam-diam salah.
--    - Bahaya sebenarnya muncul begitu recursive term BISA menemukan jalan balik ke
--      baris yang sudah pernah dikunjungi (misalnya kalau anchor/pencarian dimulai
--      dari salah satu anggota siklus, seperti pada pola Q8 yang mulai dari Bima).
--      Karena UNION ALL tidak pernah membuang baris duplikat, working table akan
--      terus tumbuh setiap iterasi dan query bisa berjalan tanpa henti sampai
--      memori/waktu habis. Siapkan Ctrl-C; jika sesi tidak responsif jalankan:
--        docker compose restart db
--    - Saat menguji secara manual, aman untuk menambah pengaman sementara seperti
--      "WHERE h.level < 20" pada SELECT terluar agar query pasti berhenti walau
--      belum diperbaiki.
-- ============================================================

-- ============================================================
-- 3) VERSI TAHAN SIKLUS (jawaban akhir)
-- ============================================================
WITH RECURSIVE hierarki AS (
    SELECT pegawai_id,
           nama,
           atasan_id,
           1 AS level,
           nama::text AS jalur,
           ARRAY[pegawai_id] AS jalur_id
    FROM pegawai
    WHERE atasan_id IS NULL

    UNION ALL

    SELECT p.pegawai_id,
           p.nama,
           p.atasan_id,
           h.level + 1,
           h.jalur || ' > ' || p.nama,
           h.jalur_id || p.pegawai_id
    FROM pegawai p
    JOIN hierarki h ON p.atasan_id = h.pegawai_id
    WHERE NOT (p.pegawai_id = ANY(h.jalur_id))   -- kunci anti-siklus
)
SELECT pegawai_id, nama, level, jalur
FROM hierarki
ORDER BY jalur;

-- ============================================================
-- 4) SETELAH PENGUJIAN, PULIHKAN DATA KE KEADAAN SEMULA:
-- ============================================================
-- UPDATE pegawai SET atasan_id = NULL WHERE pegawai_id = 1;
