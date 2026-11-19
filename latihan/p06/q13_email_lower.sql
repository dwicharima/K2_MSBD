EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id, email FROM lab6.event_log WHERE lower(email) = 'user1234567@contoh.ac.id';
