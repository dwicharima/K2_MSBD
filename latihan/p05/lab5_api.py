# Diminta: dependency koneksi bergaya with-yield yang meminjam koneksi dari pool, endpoint POST /rentals yang memanggil procedure dan mengembalikan 201, serta menerjemahkan galat database (nilai negatif, inventory tidak ada) menjadi respons HTTP yang aman tanpa membocorkan SQL.
# Dipilih: FastAPI + psycopg_pool.ConnectionPool (pola sama seperti Q14), validasi awal lewat Pydantic (Field gt=0) sebagai lapisan pertama, lalu except spesifik pada psycopg.errors untuk menerjemahkan galat basis data sebagai lapisan kedua (defense-in-depth).
# Alternatif: menampilkan str(exception) mentah dari psycopg langsung ke client; tidak dipilih karena itu membocorkan detail SQL/skema internal (nama tabel, constraint, dsb) yang tidak boleh dilihat klien.

from contextlib import contextmanager

import psycopg
from psycopg import errors as pg_errors
from psycopg_pool import ConnectionPool
from fastapi import FastAPI, Depends, HTTPException
from pydantic import BaseModel, Field

DSN = "postgresql://msbd:msbd2026@127.0.0.1:5432/pagila?connect_timeout=5"

pool = ConnectionPool(DSN, min_size=2, max_size=5, open=True)

app = FastAPI(title="Lab5 Rental API")


@app.on_event("shutdown")
def tutup_pool():
    pool.close()


# =========================================================
# Q21 - Dependency koneksi bergaya with-yield
# =========================================================
def get_conn():
    with pool.connection() as conn:
        yield conn


# =========================================================
# Skema request untuk POST /rentals
# amount wajib > 0 -- lapisan pertama (Pydantic), sebelum sempat menyentuh database
# =========================================================
class RentalIn(BaseModel):
    customer_id: int
    inventory_id: int
    staff_id: int
    amount: float = Field(gt=0, description="Nilai pembayaran, wajib positif")


class RentalOut(BaseModel):
    rental_id: int


# =========================================================
# Q22 - POST /rentals
# Q23 - amount negatif ditolak Pydantic -> 422 otomatis (bawaan FastAPI), tidak pernah sampai ke sini
# Q24 - inventory_id/customer_id/staff_id tidak ada -> ForeignKeyViolation -> 409
# =========================================================
@app.post("/rentals", response_model=RentalOut, status_code=201)
def buat_rental(payload: RentalIn, conn: psycopg.Connection = Depends(get_conn)):
    try:
        with conn.transaction():
            cur = conn.execute(
                "CALL lab5.process_rental(%s::integer, %s::integer, %s::integer, %s::numeric)",
                (payload.customer_id, payload.inventory_id, payload.staff_id, payload.amount),
            )
            row = cur.fetchone()
        rental_id = row[0]
        return RentalOut(rental_id=rental_id)

    except pg_errors.ForeignKeyViolation:
        # customer_id / inventory_id / staff_id tidak ditemukan di tabel referensi
        raise HTTPException(
            status_code=409,
            detail="Referensi tidak valid: customer, inventory, atau staff tidak ditemukan.",
        )

    except pg_errors.NumericValueOutOfRange:
        # Lapisan kedua: RAISE EXCEPTION di dalam procedure untuk p_amount <= 0
        # (jaring pengaman kalau suatu saat Pydantic dilewati, misal panggilan internal langsung ke DB)
        raise HTTPException(
            status_code=422,
            detail="Nilai pembayaran harus positif.",
        )

    except psycopg.Error:
        raise HTTPException(
            status_code=500,
            detail="Terjadi kesalahan pada server.",
        )