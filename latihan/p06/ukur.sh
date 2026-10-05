#!/usr/bin/env bash
# Pemakaian (dari ROOT repo): bash latihan/p06/ukur.sh <nama_pengukuran> <berkas_query.sql>
# Menjalankan query 3x (parallel worker dimatikan), simpan teks EXPLAIN, hitung tercepat & median.
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
NAMA="$1"; QUERY="$DIR/$2"
OUT="$DIR/explain/${NAMA}.txt"
HASIL="$DIR/hasil_pengukuran_q07_q16.md"
mkdir -p "$DIR/explain"
[ -f "$QUERY" ] || { echo "Berkas $QUERY tidak ada"; exit 1; }
: > "$OUT"
for i in 1 2 3; do
  echo "===== RUN $i =====" >> "$OUT"
  { echo "SET max_parallel_workers_per_gather = 0;"; cat "$QUERY"; } \
    | docker compose exec -T postgres psql -U msbd -d pagila -X -q -v ON_ERROR_STOP=1 >> "$OUT"
done
mapfile -t URUT < <(grep 'Execution Time' "$OUT" | awk '{print $3}')
mapfile -t SORT < <(grep 'Execution Time' "$OUT" | awk '{print $3}' | sort -n)
if [ "${#SORT[@]}" -ne 3 ]; then echo "Ditemukan ${#SORT[@]} nilai Execution Time (harus 3). Cek $OUT"; exit 1; fi
BUF=$(sed -n '/===== RUN 3/,$p' "$OUT" | grep -m1 'Buffers:' | sed 's/^ *//' || true)
if [ ! -f "$HASIL" ]; then
  echo "| Pengukuran | Tercepat (ms) | Median (ms) | Tiga waktu urut jalan (ms) | Buffers (run ke-3, node akar) |" > "$HASIL"
  echo "| --- | --- | --- | --- | --- |" >> "$HASIL"
fi
echo "| $NAMA | ${SORT[0]} | ${SORT[1]} | ${URUT[0]} / ${URUT[1]} / ${URUT[2]} | $BUF |" >> "$HASIL"
echo "=== $NAMA ==="
echo "Tercepat : ${SORT[0]} ms | Median : ${SORT[1]} ms | Urut jalan : ${URUT[*]}"
echo "$BUF"
echo "Rencana (run 3):"; sed -n '/===== RUN 3/,$p' "$OUT"
