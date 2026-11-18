#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
rentan.py - Latihan Kelompok Pertemuan 11, Langkah 4 (Q12-Q18).

Satu berkas, dua gaya pemanggilan SQL:
  * cari_rentan  : nilai masukan DITEMPEL ke teks SQL (sengaja rentan).
  * cari_aman    : nilai dikirim lewat saluran terpisah (berparameter).
  * cari_urut    : bagian yang tidak bisa diparameterkan (kolom, arah urut)
                   dijaga daftar putih tertutup.
  * second_order : nilai berbahaya disimpan lewat INSERT aman, lalu dipakai
                   oleh dua fungsi laporan (Q17).

HANYA untuk kontainer lab11 milik sendiri pada jaringan internal.
Semua payload latihan berbentuk SELECT. Sebagai jaring pengaman tambahan
(BUKAN sebagai pertahanan utama), sesi pencarian dibuka read-only.

Contoh (dijalankan di dalam kontainer lab11-web):
  python rentan.py "Pelanggan 12"                      # Q12 (rentan, postgres)
  python rentan.py "zz' OR '1'='1"                     # Q13
  python rentan.py "zz' OR '1'='1' --"                 # Q13
  python rentan.py --user app_laporan "zz' OR '1'='1' --"   # Q14
  python rentan.py --aman "zz' OR '1'='1' --"          # Q15
  python rentan.py --urut kota --arah turun "Pelanggan 12"  # Q16
  python rentan.py --urut "nama; DROP TABLE x" "Pelanggan 12"  # Q16 (ditolak)
  python rentan.py --second-order                      # Q17
"""
import argparse
import os
import sys

import psycopg2

TENANT = 1  # penyewa yang dilayani aplikasi contoh ini

# Daftar putih tertutup untuk bagian query yang tidak bisa diparameterkan.
KOLOM = {"nama": "nama", "kota": "kota", "terbaru": "dibuat_pada"}
ARAH = {"naik": "ASC", "turun": "DESC"}

# Kata sandi khusus lab (lihat docker-compose.lab11.yml dan lab11_setup.sql).
# Di sistem sungguhan kata sandi tidak boleh ada di kode; pakai DB_PASSWORD.
KATA_SANDI_LAB = {"postgres": "secretpassword"}
KATA_SANDI_LAB_DEFAULT = "lab11-pass"

PAYLOAD_STATUS = "AKTIF' OR '1'='1"  # nilai "berbahaya" untuk Q17 (hanya membaca)


def konek(user, readonly):
    kata_sandi = os.environ.get("DB_PASSWORD") or KATA_SANDI_LAB.get(
        user, KATA_SANDI_LAB_DEFAULT
    )
    conn = psycopg2.connect(
        host=os.environ.get("DB_HOST", "db"),
        port=int(os.environ.get("DB_PORT", "5432")),
        dbname=os.environ.get("DB_NAME", "msbd"),
        user=user,
        password=kata_sandi,
    )
    conn.set_session(readonly=readonly)
    return conn


def set_tenant(cur, tenant):
    # set_config(..., true) = SET LOCAL: konteks hilang saat transaksi selesai,
    # sehingga tidak tertinggal di kolam koneksi (lihat Q10).
    cur.execute("SELECT set_config('app.tenant', %s, true)", (str(tenant),))


# --------------------------------------------------------------------------
# Q12-Q14: gaya RENTAN. Perhatikan: kata masuk ke teks SQL.
# --------------------------------------------------------------------------
def cari_rentan(cur, kata):
    sql = (
        "SELECT id, nama, kota FROM lab11.pelanggan "
        f"WHERE tenant_id = {TENANT} AND nama ILIKE '%{kata}%'"
    )
    print("SQL yang dikirim ke server:")
    print("  " + sql)
    cur.execute(sql)  # tanpa argumen: seluruh teks diperlakukan sebagai KODE
    return cur.fetchall()


# --------------------------------------------------------------------------
# Q15: gaya AMAN. Nilai lewat saluran berbeda, tidak pernah menjadi kode.
# --------------------------------------------------------------------------
def cari_aman(cur, kata):
    sql = (
        "SELECT id, nama, kota FROM lab11.pelanggan "
        "WHERE tenant_id = %s AND nama ILIKE %s LIMIT 100"
    )
    param = (TENANT, f"%{kata}%")
    print("SQL yang dikirim ke server (kerangka, nilai dikirim terpisah):")
    print("  " + sql)
    print(f"Parameter (data murni): {param!r}")
    cur.execute(sql, param)
    return cur.fetchall()


# --------------------------------------------------------------------------
# Q16: nama kolom dan arah urut TIDAK bisa menjadi parameter -> daftar putih.
# --------------------------------------------------------------------------
def cari_urut(cur, kata, kolom, arah):
    if kolom not in KOLOM or arah not in ARAH:
        raise ValueError("parameter pengurutan tidak dikenal")
    sql = (
        "SELECT id, nama, kota FROM lab11.pelanggan "
        "WHERE tenant_id = %s AND nama ILIKE %s "
        f"ORDER BY {KOLOM[kolom]} {ARAH[arah]}, id LIMIT 100"
    )
    # Yang masuk ke f-string hanyalah nilai KAMUS milik kita, bukan masukan.
    print("SQL yang dikirim ke server:")
    print("  " + sql)
    cur.execute(sql, (TENANT, f"%{kata}%"))
    return cur.fetchall()


# --------------------------------------------------------------------------
# Q17: second-order. Nilai disimpan aman, bahayanya muncul saat dipakai ulang.
# --------------------------------------------------------------------------
def second_order(user):
    conn = konek(user, readonly=False)
    try:
        with conn.cursor() as cur:
            set_tenant(cur, TENANT)
            cur.execute(
                "INSERT INTO lab11.pelanggan (tenant_id, nama, kota, status) "
                "VALUES (%s, %s, %s, %s) RETURNING id, status",
                (TENANT, "Uji Second Order", "Medan", PAYLOAD_STATUS),
            )
            pid, status = cur.fetchone()
            print(f"INSERT berparameter berhasil: id={pid}, status disimpan apa adanya:")
            print(f"  {status!r}")
            for fungsi in ("laporan_kota_rentan", "laporan_kota_aman"):
                cur.execute(f"SELECT * FROM lab11.{fungsi}(%s)", (pid,))
                baris = cur.fetchall()
                print(f"\n{fungsi}({pid}) -> {len(baris)} baris, "
                      f"total={sum(b[2] for b in baris)}")
                for b in baris:
                    print("  ", b)
    finally:
        conn.rollback()  # baris uji tidak ditinggalkan
        conn.close()
        print("\n(ROLLBACK: baris uji tidak disimpan)")


def tampil(baris):
    print(f"Jumlah baris: {len(baris)}")
    for b in baris[:3]:
        print("  ", b)
    if len(baris) > 3:
        print("   ...")


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[1])
    ap.add_argument("kata", nargs="?", default="Pelanggan 12", help="kata pencarian")
    ap.add_argument("--user", default=os.environ.get("DB_USER", "postgres"),
                    help="peran koneksi (bawaan: postgres = koneksi berhak berlebihan)")
    ap.add_argument("--aman", action="store_true", help="pakai cari_aman (berparameter)")
    ap.add_argument("--urut", metavar="KOLOM", help="pakai cari_urut dengan daftar putih")
    ap.add_argument("--arah", default="naik", help="naik|turun (untuk --urut)")
    ap.add_argument("--second-order", action="store_true", help="demo Q17")
    a = ap.parse_args()

    if a.second_order:
        # Q17 jalan sebagai app_portal (peran tulis), bukan postgres.
        user = a.user if a.user != "postgres" else "app_portal"
        print(f"Peran: {user}")
        second_order(user)
        return 0

    print(f"Peran: {a.user}")
    conn = konek(a.user, readonly=True)  # jaring pengaman: sesi hanya baca
    try:
        with conn.cursor() as cur:
            set_tenant(cur, TENANT)
            if a.urut is not None:
                baris = cari_urut(cur, a.kata, a.urut, a.arah)
            elif a.aman:
                baris = cari_aman(cur, a.kata)
            else:
                baris = cari_rentan(cur, a.kata)
            tampil(baris)
    except ValueError as e:
        print(f"DITOLAK: {e}")
        return 2
    except psycopg2.Error as e:
        print(f"GALAT SQLSTATE={e.pgcode}: {(e.pgerror or str(e)).strip()}")
        return 1
    finally:
        conn.rollback()
        conn.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
