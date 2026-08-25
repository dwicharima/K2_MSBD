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

===============================================================================================

Langkah 4 : Restore Basis Data Pagila dan Verifikasi

1. Membuat database kosong
user@LAPTOP-JUQ5FG0Q MINGW64 /d/SEMESTER 3/MSBD/K2_MSBD (main)
$ docker compose exec postgres createdb -U msbd pagila

2. Restore Pagila
user@LAPTOP-JUQ5FG0Q MINGW64 /d/SEMESTER 3/MSBD/K2_MSBD (main)
$ docker compose exec postgres pg_restore -U msbd -d pagila --no-owner //dump/pagila.dump

Catatan: menggunakan "//dump/pagila.dump" (bukan "/dump/pagila.dump") karena Git Bash
(MINGW64) di Windows otomatis mengonversi path bergaya Unix menjadi path Windows lokal,
sehingga path tujuan di dalam container jadi salah. Menambahkan garis miring ganda
mencegah konversi tersebut.

3. Verifikasi tabel
user@LAPTOP-JUQ5FG0Q MINGW64 /d/SEMESTER 3/MSBD/K2_MSBD (main)
$ docker compose exec postgres psql -U msbd -d pagila -c "\dt"
                   List of relations
 Schema |       Name       |       Type        | Owner 
--------+------------------+-------------------+-------
 public | actor            | table             | msbd
 public | address          | table             | msbd
 public | category         | table             | msbd
 public | city             | table             | msbd
 public | country          | table             | msbd
 public | customer         | table             | msbd
 public | film             | table             | msbd
 public | film_actor       | table             | msbd
 public | film_category    | table             | msbd
 public | inventory        | table             | msbd
 public | language         | table             | msbd
 public | payment          | partitioned table | msbd
 public | payment_p2017_01 | table             | msbd
 public | payment_p2017_02 | table             | msbd
 public | payment_p2017_03 | table             | msbd
 public | payment_p2017_04 | table             | msbd
 public | payment_p2017_05 | table             | msbd
 public | payment_p2017_06 | table             | msbd
 public | rental           | table             | msbd
 public | staff            | table             | msbd
 public | store            | table             | msbd
(21 rows)

4. Menjalankan query verifikasi V1-V4

--> pertanma masuk ke pagila dulu

PS D:\MSBD> docker compose exec postgres psql -U msbd -d pagila         
psql (17.11 (Debian 17.11-1.pgdg13+2))
Type "help" for help.

pagila=# 

--> setelah itu masukkan query nya

== V1 ==
pagila=# SELECT count(*)
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE';
 count 
-------
    21
(1 row)

== V2 ==
pagila=# SELECT relname,
       pg_size_pretty(pg_total_relation_size(relid)) AS ukuran
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC
LIMIT 10;
     relname      | ukuran  
------------------+---------
 rental           | 2472 kB
 payment_p2017_04 | 1856 kB
 payment_p2017_03 | 1536 kB
 film             | 952 kB
 payment_p2017_02 | 728 kB
 film_actor       | 576 kB
 payment_p2017_01 | 448 kB
 inventory        | 440 kB
 customer         | 224 kB
 address          | 168 kB
(10 rows)

== V3 ==
pagila=# SELECT f.title, count(*) AS total_sewa
FROM rental r
JOIN inventory i
  ON i.inventory_id = r.inventory_id
JOIN film f
  ON f.film_id = i.film_id
GROUP BY f.title
ORDER BY total_sewa DESC
LIMIT 5;
        title        | total_sewa 
---------------------+------------
 BUCKET BROTHERHOOD  |         34
 ROCKETEER MOTHER    |         33
 RIDGEMONT SUBMARINE |         32
 SCALAWAG DUCK       |         32
 FORWARD TEMPLE      |         32
(5 rows)

== V4 ==
pagila=# EXPLAIN ANALYZE
SELECT f.title, count(*)
FROM rental r
JOIN inventory i
  ON i.inventory_id = r.inventory_id
JOIN film f
  ON f.film_id = i.film_id
GROUP BY f.title;
                                                             QUERY PLAN                                                             
------------------------------------------------------------------------------------------------------------------------------------
 HashAggregate  (cost=761.19..771.19 rows=1000 width=23) (actual time=17.885..18.086 rows=958 loops=1)
   Group Key: f.title
   Batches: 1  Memory Usage: 193kB
   ->  Hash Join  (cost=238.57..672.95 rows=17648 width=15) (actual time=2.208..13.536 rows=16044 loops=1)
         Hash Cond: (i.film_id = f.film_id)
         ->  Hash Join  (cost=128.07..515.92 rows=17648 width=2) (actual time=1.539..8.856 rows=16044 loops=1)
               Hash Cond: (r.inventory_id = i.inventory_id)
               ->  Seq Scan on rental r  (cost=0.00..341.48 rows=17648 width=4) (actual time=0.010..2.399 rows=16044 loops=1)
               ->  Hash  (cost=70.81..70.81 rows=4581 width=6) (actual time=1.511..1.513 rows=4581 loops=1)
                     Buckets: 8192  Batches: 1  Memory Usage: 234kB
                     ->  Seq Scan on inventory i  (cost=0.00..70.81 rows=4581 width=6) (actual time=0.008..0.708 rows=4581 loops=1)
         ->  Hash  (cost=98.00..98.00 rows=1000 width=19) (actual time=0.661..0.662 rows=1000 loops=1)
               Buckets: 1024  Batches: 1  Memory Usage: 60kB
               ->  Seq Scan on film f  (cost=0.00..98.00 rows=1000 width=19) (actual time=0.015..0.382 rows=1000 loops=1)
 Planning Time: 0.628 ms
 Execution Time: 18.193 ms
(16 rows)
 