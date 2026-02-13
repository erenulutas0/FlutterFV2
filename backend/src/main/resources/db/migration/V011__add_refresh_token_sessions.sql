CREATE TABLE IF NOT EXISTS refresh_token_sessions (
    id BIGSERIAL PRIMARY KEY,
    session_id VARCHAR(64) NOT NULL UNIQUE,
    user_id BIGINT NOT NULL,
    token_hash VARCHAR(128) NOT NULL,
    device_id VARCHAR(128),
    user_agent VARCHAR(512),
    created_ip VARCHAR(64),
    last_used_ip VARCHAR(64),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_used_at TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    revoked_at TIMESTAMP,
    revoke_reason VARCHAR(64),
    replaced_by_session_id VARCHAR(64),
    parent_session_id VARCHAR(64),
    remember_me BOOLEAN NOT NULL DEFAULT FALSE,
    reuse_detected_at TIMESTAMP,
    CONSTRAINT fk_refresh_token_sessions_user
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_refresh_token_sessions_user_id
    ON refresh_token_sessions(user_id);

CREATE INDEX IF NOT EXISTS idx_refresh_token_sessions_expires_at
    ON refresh_token_sessions(expires_at);

CREATE INDEX IF NOT EXISTS idx_refresh_token_sessions_revoked_at
    ON refresh_token_sessions(revoked_at);

CREATE INDEX IF NOT EXISTS idx_refresh_token_sessions_parent
    ON refresh_token_sessions(parent_session_id);
