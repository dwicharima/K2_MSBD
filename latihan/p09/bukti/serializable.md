# Q27–Q29 — SERIALIZABLE, SIReadLock, dan Retry Transaksi

**Alat:** psql di Docker (`msbd-pg`), PostgreSQL 17.11.

## Q27 — SERIALIZABLE Mencegah Write Skew

### Persiapan Data

```sql
TRUNCATE TABLE lab9.dokter_jaga;

INSERT INTO lab9.dokter_jaga (dokter_id, nama, aktif)
VALUES
    (1, 'Ani', TRUE),
    (2, 'Budi', TRUE);
```

### Sesi A

```sql
BEGIN ISOLATION LEVEL SERIALIZABLE;

SELECT COUNT(*) AS dokter_aktif
FROM lab9.dokter_jaga
WHERE aktif = TRUE;

UPDATE lab9.dokter_jaga
SET aktif = FALSE
WHERE dokter_id = 1;

COMMIT;
```

### Sesi B

```sql
BEGIN ISOLATION LEVEL SERIALIZABLE;

SELECT COUNT(*) AS dokter_aktif
FROM lab9.dokter_jaga
WHERE aktif = TRUE;

UPDATE lab9.dokter_jaga
SET aktif = FALSE
WHERE dokter_id = 2;

COMMIT;
```

### Hasil Pengujian

Salah satu transaksi dapat dibatalkan dengan error seperti berikut:

```text
ERROR: could not serialize access due to read/write dependencies among transactions
DETAIL: Reason code: Canceled on identification as a pivot, during commit attempt.
HINT: The transaction might succeed if retried.
```

Hasil akhir yang diperoleh pada pengujian:

```text
 dokter_id | nama | aktif
-----------+------+-------
         1 | Ani  | f
         2 | Budi | t
(2 rows)
```

**Kesimpulan:** `SERIALIZABLE` mencegah hasil transaksi yang tidak setara dengan urutan serial. Salah satu transaksi dibatalkan karena konflik serialisasi.

## Q28 — SIReadLock

`SIReadLock` digunakan PostgreSQL pada isolation level `SERIALIZABLE` untuk melacak data yang dibaca transaksi dan mendeteksi ketergantungan baca-tulis yang berpotensi menyebabkan hasil transaksi tidak serial.

Lock ini berbeda dari row lock biasa karena tidak bertujuan menghalangi transaksi lain mengubah baris. Informasi ketergantungannya digunakan untuk menentukan apakah suatu transaksi perlu dibatalkan demi menjaga serialisasi.

## Q29 — Retry Transaksi

Transaksi yang gagal karena SQLSTATE `40001` (*serialization_failure*) atau `40P01` (*deadlock_detected*) dapat dicoba kembali.

Pseudocode:

```text
maks_percobaan = 3

untuk percobaan dari 1 sampai maks_percobaan:
    mulai transaksi
    jalankan seluruh operasi transaksi

    jika transaksi berhasil:
        COMMIT
        hentikan pengulangan

    jika terjadi error 40001 atau 40P01:
        ROLLBACK

        jika masih ada kesempatan:
            tunggu sebentar sebelum mencoba kembali
        jika tidak:
            laporkan kegagalan

    jika terjadi error lain:
        ROLLBACK
        laporkan kegagalan
```

**Kesimpulan:** Retry dilakukan terhadap seluruh transaksi, bukan hanya query yang gagal. Jumlah percobaan perlu dibatasi agar proses tidak berulang tanpa henti.