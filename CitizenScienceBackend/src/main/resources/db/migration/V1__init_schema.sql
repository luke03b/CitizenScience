-- ═══════════════════════════════════════════════════════════════
-- CITIZEN SCIENCE - Schema Completo
-- ═══════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════
-- ESTENSIONE POSTGIS
-- ═══════════════════════════════════════════════════════════════

CREATE EXTENSION IF NOT EXISTS postgis;

-- ═══════════════════════════════════════════════════════════════
-- TABELLA USERS
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome VARCHAR(255) NOT NULL,
    cognome VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    ruolo VARCHAR(50) NOT NULL CHECK (ruolo IN ('utente', 'ricercatore'))
);

-- ═══════════════════════════════════════════════════════════════
-- TABELLA AVVISTAMENTI
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE avvistamenti (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome VARCHAR(255) DEFAULT 'Avvistamento',
    posizione GEOMETRY(Point, 4326),
    latitudine DOUBLE PRECISION NOT NULL,
    longitudine DOUBLE PRECISION NOT NULL,
    data TIMESTAMP NOT NULL,
    user_id UUID NOT NULL,
    note TEXT,
    indirizzo VARCHAR(500),
    ai_model_used VARCHAR(255),
    ai_confidence DOUBLE PRECISION,
    CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_avvistamenti_posizione ON avvistamenti USING GIST(posizione);
CREATE INDEX idx_avvistamenti_user ON avvistamenti(user_id);
CREATE INDEX idx_avvistamenti_ai_model ON avvistamenti(ai_model_used);

-- ═══════════════════════════════════════════════════════════════
-- TABELLA FOTO_AVVISTAMENTI
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE foto_avvistamenti (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    avvistamento_id UUID NOT NULL,
    photo_path VARCHAR(500) NOT NULL,
    CONSTRAINT fk_avvistamento FOREIGN KEY (avvistamento_id) REFERENCES avvistamenti(id) ON DELETE CASCADE
);

CREATE INDEX idx_foto_avvistamento ON foto_avvistamenti(avvistamento_id);

-- ═══════════════════════════════════════════════════════════════
-- TABELLA AI_MODEL_SELECTION
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE ai_model_selection (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    model_name VARCHAR(255) NOT NULL,
    selected_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT unique_user_model UNIQUE (user_id)
);

CREATE INDEX idx_ai_model_selection_user_id ON ai_model_selection(user_id);
