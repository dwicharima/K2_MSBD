
-- Query Verifikasi
-- =============================================================

-- V1 --
SELECT count(*)
FROM information_schema.tables
WHERE table_schema = 'public'
    AND table_type = 'BASE TABLE';
-- Nilai rujukan: 21 tabel.


-- V2 --
SELECT relname,
        pg_size_pretty(pg_total_relation_size(relid)) AS ukuran
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC
LIMIT 10;


-- V3 --
SELECT f.title, count(*) AS total_sewa
FROM rental r
JOIN inventory i
    ON i.inventory_id = r.inventory_id
JOIN film f
    ON f.film_id = i.film_id
GROUP BY f.title
ORDER BY total_sewa DESC
LIMIT 5;


-- V4 --
EXPLAIN ANALYZE
SELECT f.title, count(*)
FROM rental r
JOIN inventory i
    ON i.inventory_id = r.inventory_id
JOIN film f
    ON f.film_id = i.film_id
GROUP BY f.title;
