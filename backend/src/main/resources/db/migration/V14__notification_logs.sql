CREATE TABLE notification_logs (
    id            BIGSERIAL PRIMARY KEY,
    user_id       BIGINT       NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type          VARCHAR(64)  NOT NULL,
    title         VARCHAR(255) NOT NULL,
    body          TEXT         NOT NULL,
    status        VARCHAR(32)  NOT NULL DEFAULT 'SENT',
    fcm_token     VARCHAR(500),
    error_message VARCHAR(500),
    sent_at       TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notification_logs_user_id   ON notification_logs(user_id);
CREATE INDEX idx_notification_logs_type_sent ON notification_logs(type, sent_at DESC);
