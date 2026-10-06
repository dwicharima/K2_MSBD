SELECT
    relname AS tabel,
    indexrelname AS nama_index,
    idx_scan,
    pg_size_pretty(
        pg_relation_size(indexrelid)
    ) AS ukuran
FROM pg_stat_user_indexes
WHERE schemaname = 'lab6'
  AND idx_scan = 0
ORDER BY relname, indexrelname;