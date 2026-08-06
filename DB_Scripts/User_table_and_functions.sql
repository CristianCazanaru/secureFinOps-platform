-- =============================================================================
-- Users table with encrypted PII (CNP, nume, prenume)
-- Uses pgcrypto for AES-based symmetric encryption via pgp_sym_encrypt/decrypt
-- =============================================================================

-- pgcrypto provides both the encryption functions AND gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- -----------------------------------------------------------------------------
-- Table
-- -----------------------------------------------------------------------------
-- nume, prenume, socialsecno are stored as BYTEA (encrypted binary), not TEXT.
-- They are encripted directly in the DB without the encryption key.
CREATE TABLE IF NOT EXISTS users (
    userid       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username     VARCHAR(255) NOT NULL UNIQUE,
    nume         BYTEA NOT NULL,
    prenume      BYTEA NOT NULL,
    socialsecno  BYTEA NOT NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- -----------------------------------------------------------------------------
-- Generic encrypt / decrypt — reusable for any field
-- -----------------------------------------------------------------------------
-- encryption_key is passed as a parameter at call time. It must NEVER be
-- hardcoded here or committed to git — it comes from an env var / secrets
-- manager at the application layer (see notes at the bottom of this file).

CREATE OR REPLACE FUNCTION encrypt_field(plain_text TEXT, encryption_key TEXT)
RETURNS BYTEA AS $$
BEGIN
    IF plain_text IS NULL OR encryption_key IS NULL THEN
        RAISE EXCEPTION 'encrypt_field: plain_text and encryption_key are required';
    END IF;
    -- pgp_sym_encrypt embeds random salt automatically, so encrypting the
    -- same value twice produces different ciphertext each time.
    RETURN pgp_sym_encrypt(plain_text, encryption_key);
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION decrypt_field(encrypted_data BYTEA, encryption_key TEXT)
RETURNS TEXT AS $$
BEGIN
    IF encrypted_data IS NULL OR encryption_key IS NULL THEN
        RAISE EXCEPTION 'decrypt_field: encrypted_data and encryption_key are required';
    END IF;
    RETURN pgp_sym_decrypt(encrypted_data, encryption_key);
EXCEPTION
    WHEN OTHERS THEN
        -- Wrong key produces a decryption error, not garbage text — fail loudly.
        RAISE EXCEPTION 'decrypt_field: decryption failed (wrong key or corrupted data)';
END;
$$ LANGUAGE plpgsql;

-- -----------------------------------------------------------------------------
-- CNP-specific encryption — validates format, then delegates to encrypt_field
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION encrypt_cnp(cnp TEXT, encryption_key TEXT)
RETURNS BYTEA AS $$
BEGIN
    IF cnp !~ '^[0-9]{13}$' THEN
        RAISE EXCEPTION 'encrypt_cnp: CNP must be exactly 13 digits';
    END IF;
    RETURN encrypt_field(cnp, encryption_key);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION decrypt_cnp(encrypted_cnp BYTEA, encryption_key TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN decrypt_field(encrypted_cnp, encryption_key);
END;
$$ LANGUAGE plpgsql;

-- -----------------------------------------------------------------------------
-- Nume / Prenume encryption — thin wrappers, kept separate so call sites
-- read clearly (encrypt_nume(...) vs generic encrypt_field(...))
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION encrypt_nume(value TEXT, encryption_key TEXT)
RETURNS BYTEA AS $$
BEGIN
    RETURN encrypt_field(value, encryption_key);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION decrypt_nume(encrypted_value BYTEA, encryption_key TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN decrypt_field(encrypted_value, encryption_key);
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- USAGE EXAMPLE
-- =============================================================================
-- userid is generated automatically (DEFAULT gen_random_uuid()) — no need to
-- call a separate function for it at insert time.
--
-- INSERT INTO users (username, nume, prenume, socialsecno)
-- VALUES (
--     'cristian.c',
--     encrypt_nume('Cazanaru', :'app_key'),
--     encrypt_nume('Cristian-Sabin', :'app_key'),
--     encrypt_cnp('1900101123456', :'app_key')
-- );
--
-- SELECT
--     userid,
--     username,
--     decrypt_nume(nume, :'app_key')        AS nume,
--     decrypt_nume(prenume, :'app_key')     AS prenume,
--     decrypt_cnp(socialsecno, :'app_key')  AS cnp
-- FROM users
-- WHERE username = 'cristian.c';

-- =============================================================================
-- SECURITY NOTES — read before using this in anything real
-- =============================================================================
-- 1. NEVER hardcode encryption_key in this file or any committed SQL/config.
--    Pass it at runtime from an environment variable or secrets manager
--    (AWS Secrets Manager, Vault, Jenkins credentials, etc.) — same principle
--    as DB_PASSWORD in your Jenkins pipeline.
--
-- 2. If the encryption key is ever lost, the encrypted data is permanently
--    unrecoverable — there is no "reset" for pgp_sym_encrypt. Plan key
--    storage/backup accordingly.
--
-- 3. Encrypted columns cannot be searched directly with WHERE nume = 'X',
--    because pgp_sym_encrypt output differs every time even for the same
--    input (random salt). If you need to look up users by name, you'd add
--    a separate deterministic HMAC "blind index" column purely for lookups,
--    keeping the encrypted column as the source of truth. Not implemented
--    here — flag if you want it added.
--
-- 4. CNP is highly sensitive PII (Romanian national ID). Treat the
--    encryption key with the same care as a database root password —
--    rotate it, restrict who/what can read it, and never log it.
--
-- 5. This uses symmetric encryption (same key encrypts and decrypts).
--    For a portfolio, this is the standard, expected approach. Asymmetric
--    (public/private key) encryption is a different pattern used for
--    different threat models — not needed here.