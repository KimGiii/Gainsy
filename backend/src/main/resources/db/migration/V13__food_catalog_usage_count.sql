-- Phase 1: usage_count 컬럼 추가
ALTER TABLE food_catalog
    ADD COLUMN IF NOT EXISTS usage_count BIGINT NOT NULL DEFAULT 0;

-- Phase 2: 기존 데이터 백필 (살아있는 식단의 food_entries 기준 집계)
UPDATE food_catalog fc
SET usage_count = (
    SELECT COUNT(*)
    FROM food_entries fe
    JOIN diet_logs dl ON dl.id = fe.diet_log_id
    WHERE fe.food_catalog_id = fc.id
      AND dl.deleted_at IS NULL
);

-- Phase 3: 정렬 성능 인덱스
CREATE INDEX IF NOT EXISTS idx_food_catalog_usage
    ON food_catalog (usage_count DESC, name_ko ASC)
    WHERE deleted_at IS NULL;

-- Phase 4: 사용자 직접 등록 식품 중복 방지 (이름+카테고리 기준)
CREATE UNIQUE INDEX IF NOT EXISTS uq_food_catalog_custom_name_category
    ON food_catalog (LOWER(name_ko), category)
    WHERE deleted_at IS NULL AND is_custom = TRUE;
