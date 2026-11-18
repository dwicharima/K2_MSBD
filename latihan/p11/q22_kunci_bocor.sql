SELECT pid, usename, state, left(query, 160) AS query
FROM pg_stat_activity
WHERE state = 'active'
  AND query ILIKE '%pgp_sym_encrypt%'
  AND pid <> pg_backend_pid();

SHOW log_statement;
SHOW log_min_duration_statement;
SELECT name, setting FROM pg_settings WHERE name IN ('log_statement', 'log_min_duration_statement',
                                                    'log_parameter_max_length', 'track_activity_query_size');
SHOW shared_preload_libraries;
SELECT extname FROM pg_extension WHERE extname = 'pg_stat_statements';
