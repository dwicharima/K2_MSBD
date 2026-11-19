import psycopg

DSN = "postgresql://msbd:msbd2026@127.0.0.1:5432/pagila?connect_timeout=5"

payload = "SMITH' OR '1'='1"

# 1) Cetak SQL hasil f-string (JANGAN dijalankan / dieksekusi ke DB)
query_rawan = f"SELECT * FROM customer WHERE last_name = '{payload}'"
print("SQL rawan (hanya dicetak, TIDAK dijalankan):")
print(query_rawan)

# 2) Jalankan versi BERPARAMETER dengan payload yang sama -> buktikan hasil kosong
print("\nMenjalankan versi aman (parameterized) dengan payload yang sama:")
with psycopg.connect(DSN) as conn:
    with conn.cursor() as cur:
        cur.execute("SELECT * FROM customer WHERE last_name = %s", (payload,))
        hasil = cur.fetchall()
        print("Hasil (harus kosong []):", hasil)
