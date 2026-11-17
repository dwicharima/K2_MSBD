-- Diminta: membuktikan REVOKE biasa pada pemilik bisa dibatalkan pemilik sendiri.
-- Dipilih: REVOKE lalu GRANT oleh skema_owner, supaya terlihat hak biasa vs hak kepemilikan.
-- Alternatif: hanya mengandalkan REVOKE; tidak dipilih karena tidak menutup K1.
--- 1. REVOKE UPDATE dari skema_owner (dijalankan sebagai postgres)
REVOKE UPDATE ON lab11.pelanggan FROM skema_owner;
SET ROLE skema_owner;
SELECT current_user AS peran_aktif;
--- 2. UPDATE sebagai skema_owner (harapkan: permission denied)
BEGIN; UPDATE lab11.pelanggan SET kota = kota WHERE id = 3; ROLLBACK;
--- 3. GRANT UPDATE oleh skema_owner sendiri
GRANT UPDATE ON lab11.pelanggan TO skema_owner;
--- 4. UPDATE lagi (harapan: UPDATE 1)
BEGIN; UPDATE lab11.pelanggan SET kota = kota WHERE id = 3; ROLLBACK;
RESET ROLE;