Langkah 1 :










Langkah 2 :

1. Membuat direktori dump
AGNES@LAPTOP-1T3ANVB7 MINGW64 ~/msbd-2026 (main)
$ mkdir -p dump

2. Menjalankan Docker Compose
AGNES@LAPTOP-1T3ANVB7 MINGW64 ~/msbd-2026 (main)
$ docker compose up -d
[+] up 3/3
 ✔️ Container msbd-pg    Running                                                                                                                            0.0s
 ✔️ Container msbd-mongo Running                                                                                                                            0.0s
 ✔️ Container msbd-redis Running                                                                                                                            0.0s

3. Mengecek Status Container
AGNES@LAPTOP-1T3ANVB7 MINGW64 ~/msbd-2026 (main)
$ docker compose ps
NAME         IMAGE            COMMAND                  SERVICE    CREATED       STATUS                 PORTS
msbd-mongo   mongo:8          "docker-entrypoint.s…"   mongo      2 hours ago   Up 2 hours             0.0.0.0:27017->27017/tcp, [::]:27017->27017/tcp
msbd-pg      postgres:17      "docker-entrypoint.s…"   postgres   2 hours ago   Up 2 hours (healthy)   0.0.0.0:5432->5432/tcp, [::]:5432->5432/tcp
msbd-redis   redis:7-alpine   "docker-entrypoint.s…"   redis      2 hours ago   Up 2 hours             0.0.0.0:6379->6379/tcp, [::]:6379->6379/tcp

4. Melihat Log Postgres
AGNES@LAPTOP-1T3ANVB7 MINGW64 ~/msbd-2026 (main)
$ docker compose logs postgres | tail -20
msbd-pg  | /usr/local/bin/docker-entrypoint.sh: ignoring /docker-entrypoint-initdb.d/*
msbd-pg  | 
msbd-pg  | waiting for server to shut down....2026-08-25 07:39:05.392 UTC [49] LOG:  received fast shutdown request
msbd-pg  | 2026-08-25 07:39:05.394 UTC [49] LOG:  aborting any active transactions
msbd-pg  | 2026-08-25 07:39:05.396 UTC [49] LOG:  background worker "logical replication launcher" (PID 55) exited with exit code 1
msbd-pg  | 2026-08-25 07:39:05.399 UTC [50] LOG:  shutting down
msbd-pg  | 2026-08-25 07:39:05.402 UTC [50] LOG:  checkpoint starting: shutdown immediate
msbd-pg  | 2026-08-25 07:39:05.666 UTC [50] LOG:  checkpoint complete: wrote 925 buffers (5.6%); 0 WAL file(s) added, 0 removed, 0 recycled; write=0.031 s, sync=0.223 s, total=0.267 s; sync files=301, longest=0.005 s, average=0.001 s; distance=4256 kB, estimate=4256 kB; lsn=0/19179A0, redo lsn=0/19179A0
msbd-pg  | 2026-08-25 07:39:05.670 UTC [49] LOG:  database system is shut down
msbd-pg  |  done
msbd-pg  | server stopped
msbd-pg  | 
msbd-pg  | PostgreSQL init process complete; ready for start up.
msbd-pg  | 
msbd-pg  | 2026-08-25 07:39:05.714 UTC [1] LOG:  starting PostgreSQL 17.11 (Debian 17.11-1.pgdg13+2) on x86_64-pc-linux-gnu, compiled by gcc (Debian 14.2.0-19) 14.2.0, 64-bit
msbd-pg  | 2026-08-25 07:39:05.714 UTC [1] LOG:  listening on IPv4 address "0.0.0.0", port 5432
msbd-pg  | 2026-08-25 07:39:05.714 UTC [1] LOG:  listening on IPv6 address "::", port 5432
msbd-pg  | 2026-08-25 07:39:05.719 UTC [1] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
msbd-pg  | 2026-08-25 07:39:05.725 UTC [65] LOG:  database system was shut down at 2026-08-25 07:39:05 UTC
msbd-pg  | 2026-08-25 07:39:05.730 UTC [1] LOG:  database system is ready to accept connections