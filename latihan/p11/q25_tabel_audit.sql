-- Diminta: membuat tabel dan trigger audit.
-- Dipilih: SECURITY DEFINER dan session_user agar aktivitas tercatat.
-- Alternatif: INSERT langsung oleh aplikasi; tidak dipilih agar audit tidak dipalsukan.

CREATE TABLE IF NOT EXISTS lab11.jejak_audit (
    id BIGSERIAL PRIMARY KEY,
    waktu TIMESTAMPTZ NOT NULL DEFAULT now(),
    pelaku TEXT NOT NULL,
    aksi TEXT NOT NULL,
    nama_tabel TEXT NOT NULL,
    kunci TEXT,
    nilai_lama JSONB,
    nilai_baru JSONB
);

CREATE OR REPLACE FUNCTION lab11.rekam_audit()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, lab11
AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO lab11.jejak_audit (
            pelaku, aksi, nama_tabel,
            kunci, nilai_lama, nilai_baru
        )
        VALUES (
            session_user,
            TG_OP,
            TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME,
            OLD.id::TEXT,
            to_jsonb(OLD),
            to_jsonb(NEW)
        );

        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO lab11.jejak_audit (
            pelaku, aksi, nama_tabel,
            kunci, nilai_lama, nilai_baru
        )
        VALUES (
            session_user,
            TG_OP,
            TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME,
            OLD.id::TEXT,
            to_jsonb(OLD),
            NULL
        );

        RETURN OLD;
    END IF;

    RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_rekam_audit
ON lab11.pelanggan;

CREATE TRIGGER trg_rekam_audit
AFTER UPDATE OR DELETE
ON lab11.pelanggan
FOR EACH ROW
EXECUTE FUNCTION lab11.rekam_audit();

-- Aplikasi tidak boleh menulis langsung ke tabel audit.
REVOKE ALL ON lab11.jejak_audit FROM PUBLIC;
REVOKE ALL ON lab11.jejak_audit
FROM app_portal, app_write, app_read, app_laporan, app_analitik;

REVOKE ALL ON SEQUENCE lab11.jejak_audit_id_seq
FROM PUBLIC, app_portal, app_write, app_read, app_laporan, app_analitik;

-- Pemeriksaan trigger.
SELECT
    trigger_name,
    event_manipulation,
    event_object_table
FROM information_schema.triggers
WHERE trigger_schema = 'lab11'
  AND event_object_table = 'pelanggan';