EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM lab6.event_log
WHERE status = 'GAGAL';docker compose exec -T postgres psql -U msbd -d latihan < latihan/p06/q23_gagal.sql