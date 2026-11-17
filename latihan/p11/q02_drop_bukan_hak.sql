-- Diminta: mencoba mencabut DROP dari pemilik dan mengutip galatnya.
-- Dipilih: REVOKE DROP apa adanya, supaya galat aslinya terlihat.
-- Alternatif: ALTER TABLE ... OWNER TO; itu memindahkan pemilik, bukan mencabut hak.
--- REVOKE DROP (harapan galat)
REVOKE DROP ON lab11.akun FROM skema_owner;
