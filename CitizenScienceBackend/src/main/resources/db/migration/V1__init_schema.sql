-- ═══════════════════════════════════════════════════════════════
-- CITIZEN SCIENCE - Schema Iniziale
-- ═══════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════
-- ESTENSIONE POSTGIS
-- ═══════════════════════════════════════════════════════════════

CREATE EXTENSION IF NOT EXISTS postgis;

-- ═══════════════════════════════════════════════════════════════
-- TABELLA USERS - Utenti registrati
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    username VARCHAR(100) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);

-- ═══════════════════════════════════════════════════════════════
-- TABELLA SIGHTINGS - Avvistamenti fiori
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE sightings (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    flower_name VARCHAR(200) NOT NULL,
    description TEXT,
    location GEOMETRY(Point, 4326) NOT NULL,
    sighting_date TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sightings_location ON sightings USING GIST(location);
CREATE INDEX idx_sightings_user_id ON sightings(user_id);
CREATE INDEX idx_sightings_date ON sightings(sighting_date DESC);

-- ═══════════════════════════════════════════════════════════════
-- TABELLA SIGHTING_PHOTOS - Foto degli avvistamenti
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE sighting_photos (
    id BIGSERIAL PRIMARY KEY,
    sighting_id BIGINT NOT NULL REFERENCES sightings(id) ON DELETE CASCADE,
    file_path VARCHAR(500) NOT NULL,
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    uploaded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sighting_photos_sighting_id ON sighting_photos(sighting_id);