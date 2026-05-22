-- 프리미엄 기능 게이팅용 플래그.
-- 사진 기반 영양 분석 등 유료 기능은 is_premium=TRUE 사용자만 접근 가능.
-- 결제 시스템(StoreKit IAP, 영수증 검증)은 후속 PR에서 도입한다.
ALTER TABLE users
    ADD COLUMN is_premium BOOLEAN NOT NULL DEFAULT FALSE;

CREATE INDEX idx_users_is_premium ON users(is_premium) WHERE is_premium = TRUE;
