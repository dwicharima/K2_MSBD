SELECT label AS index, pg_size_pretty(bytes) AS ukuran, bytes,
       round(bytes/2000000.0, 2) AS byte_per_entri,
       round(bytes/8192.0)       AS halaman_8kb
FROM (SELECT DISTINCT ON (label) label, bytes FROM lab6.p06_ukuran_index
      WHERE label IN ('ev_salah_idx','ev_benar_idx') ORDER BY label, dicatat DESC) t
ORDER BY label;
SELECT round(100.0*(max(bytes)-min(bytes))/max(bytes), 2) AS selisih_persen
FROM (SELECT DISTINCT ON (label) label, bytes FROM lab6.p06_ukuran_index
      WHERE label IN ('ev_salah_idx','ev_benar_idx') ORDER BY label, dicatat DESC) t;
