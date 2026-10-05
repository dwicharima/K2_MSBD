VACUUM (ANALYZE) lab6.event_log;
ALTER TABLE lab6.event_log RESET (autovacuum_enabled);
SELECT relpages, relallvisible FROM pg_class WHERE oid = 'lab6.event_log'::regclass;
SELECT reloptions FROM pg_class WHERE oid = 'lab6.event_log'::regclass;
