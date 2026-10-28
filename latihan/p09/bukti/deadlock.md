# Q24–Q25 — Pengujian Row Lock: SKIP LOCKED dan NOWAIT

## Q24 — SKIP LOCKED

### Sesi A

```sql
BEGIN;

SELECT *
FROM lab9.antrean_pekerjaan
WHERE id = 1
FOR UPDATE;
```

Transaksi Sesi A menahan lock pada baris dengan ID 1. Transaksi tidak boleh di-COMMIT sebelum query Sesi B dijalankan.

### Sesi B

```sql
BEGIN;

SELECT *
FROM lab9.antrean_pekerjaan
WHERE status = 'menunggu'
ORDER BY id
FOR UPDATE SKIP LOCKED;
```

### Hasil yang Diharapkan

```text
 id |  status
----+---------
  2 | menunggu
  3 | menunggu
(2 rows)
```

**Kesimpulan:** `SKIP LOCKED` melewati baris yang sedang dikunci transaksi lain sehingga baris ID 1 tidak ikut ditampilkan.

## Q25 — NOWAIT

### Sesi A

```sql
BEGIN;

SELECT *
FROM lab9.antrean_pekerjaan
WHERE id = 1
FOR UPDATE;
```

Biarkan transaksi tetap terbuka saat menjalankan query Sesi B.

### Sesi B

```sql
BEGIN;

SELECT *
FROM lab9.antrean_pekerjaan
WHERE id = 1
FOR UPDATE NOWAIT;
```

### Hasil Pengujian

```text
ERROR: could not obtain lock on row in relation "antrean_pekerjaan"
```

**Kesimpulan:** `NOWAIT` langsung menghasilkan error ketika baris yang diminta sedang dikunci transaksi lain, tanpa menunggu lock dilepas.

**Catatan:** Pengujian ini membahas mekanisme row lock, bukan simulasi deadlock secara langsung. Hasil `SKIP LOCKED` dan `NOWAIT` perlu dijalankan ketika lock Sesi A masih aktif agar membuktikan perilaku tersebut.