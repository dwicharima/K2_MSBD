import time
import psycopg
from psycopg import sql
from psycopg_pool import ConnectionPool

DSN = "postgresql://msbd:msbd2026@127.0.0.1:5432/pagila?connect_timeout=5"


# ---------------------------------------------------------------------
# Q10 - SELECT berparameter
# ---------------------------------------------------------------------
def q10_select_berparameter():
    print("\n=== Q10: SELECT berparameter ===")
    query = "SELECT * FROM film WHERE title = %s"
    parameter = ("ACADEMY DINOSAUR",)
    with psycopg.connect(DSN) as conn:
        with conn.cursor() as cur:
            # Ganti nama tabel/kolom sesuai skema lab5 kamu
            cur.execute(query, parameter)
            hasil = cur.fetchall()
            print("Query:", query)
            print("Parameter:", parameter)
            print("Hasil:", hasil)


# ---------------------------------------------------------------------
# Q11 ada di file TERPISAH: q11_uji_injeksi.py (lihat file itu)
# ---------------------------------------------------------------------


# ---------------------------------------------------------------------
# Q12 - Identifier dan allow-list
# ---------------------------------------------------------------------
ALLOWED_COLUMNS = {"title", "release_year", "rental_rate"}  # allow-list tertutup

def q12_identifier_allowlist(kolom_order_by: str):
    print("\n=== Q12: Identifier & allow-list ===")

    # Langkah A: coba kirim nama kolom sebagai PARAMETER NILAI (%s) -> harus GAGAL
    try:
        with psycopg.connect(DSN) as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT * FROM film ORDER BY %s", (kolom_order_by,))
                print("Berhasil dieksekusi, tetapi parameter dianggap sebagai nilai konstan, bukan nama kolom")
    except Exception as e:
        print("GAGAL (sesuai dugaan) saat ORDER BY pakai %s:", e)

    # Langkah B: perbaikan pakai sql.Identifier + allow-list
    if kolom_order_by not in ALLOWED_COLUMNS:
        raise ValueError(f"Kolom '{kolom_order_by}' tidak diizinkan (allow-list tertutup)")

    with psycopg.connect(DSN) as conn:
        with conn.cursor() as cur:
            query = sql.SQL("SELECT * FROM film ORDER BY {}").format(
                sql.Identifier(kolom_order_by)
            )
            cur.execute(query)
            print("Query setelah perbaikan:", query.as_string(conn))
            print("Hasil:", cur.fetchall()[:5])  # tampilkan sebagian saja


# ---------------------------------------------------------------------
# Q13 - Rollback dari aplikasi
# ---------------------------------------------------------------------
def hitung_baris_rental(conn):
    with conn.cursor() as cur:
        cur.execute("SELECT COUNT(*) FROM rental")
        return cur.fetchone()[0]


def q13_rollback_aplikasi():
    print("\n=== Q13: Rollback dari aplikasi ===")
    with psycopg.connect(DSN) as conn:
        sebelum = hitung_baris_rental(conn)
        print("Jumlah baris SEBELUM:", sebelum)

        try:
            with conn.transaction():  # blok transaksi otomatis (commit/rollback)
                conn.execute(
                    "CALL lab5.process_rental(%s::integer, %s::integer, "
                    "%s::integer, %s::numeric)",
                    (1, 1, 1, 4.99),
                )
                raise RuntimeError("gagal di tengah alur")
        except RuntimeError as e:
            print("Exception ditangkap:", e)

        sesudah = hitung_baris_rental(conn)
        print("Jumlah baris SESUDAH:", sesudah)
        print("Penjelasan: karena exception dilempar SEBELUM blok 'with conn.transaction()' selesai, "
                "psycopg otomatis ROLLBACK seluruh transaksi -> jumlah baris tidak berubah.")


# ---------------------------------------------------------------------
# Q14 - ConnectionPool
# ---------------------------------------------------------------------
def q14_connection_pool():
    print("\n=== Q14: ConnectionPool ===")
    with ConnectionPool(DSN, min_size=2, max_size=2) as pool:
        for i in range(5):
            with pool.connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("SELECT 1")
                    cur.fetchone()
        print("Statistik pool:", pool.get_stats())


# ---------------------------------------------------------------------
# Q15 - Idle in transaction
# ---------------------------------------------------------------------
def q15_idle_in_transaction():
    print("\n=== Q15: Idle in transaction ===")
    print("Jalankan blok ini, LALU di psql/terminal lain (SELESAI dalam 30 detik) jalankan:")
    print("  SELECT pid, state, xact_start, query FROM pg_stat_activity WHERE state LIKE 'idle in%';")
    import time
    with psycopg.connect(DSN) as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT 1")  # transaksi mulai, belum commit
            print("Transaksi dibuka, tidur 30 detik... (jangan tutup koneksi ini)")
            time.sleep(30)
    print("Selesai, transaksi otomatis commit/close di sini.")


# ---------------------------------------------------------------------
# MAIN - jalankan satu per satu, komentari yang belum dikerjakan
# ---------------------------------------------------------------------
if __name__ == "__main__":
    q10_select_berparameter()
    q12_identifier_allowlist("release_year")
    q13_rollback_aplikasi()
    q14_connection_pool()
    # q15_idle_in_transaction()   # aktifkan terakhir, perlu 2 terminal
