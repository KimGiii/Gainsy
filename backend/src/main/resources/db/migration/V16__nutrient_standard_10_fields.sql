-- 영양소 표준 10종 통일 마이그레이션
-- 기존 4종(칼로리/단백/탄수/지방) + 신규 6종(당류/식이섬유/포화지방/트랜스지방/콜레스테롤/나트륨)
-- 식약처 영양표시기준 + 공공 식품영양성분 API 반환 항목 기반.
-- 기존 데이터는 NULL 허용. 신규 컬럼은 추후 임포트·재계산 시 채워진다.

-- ─────────────────────── food_catalog (100g 기준) ───────────────────────
ALTER TABLE food_catalog
    ADD COLUMN sugars_per_100g         DOUBLE PRECISION,
    ADD COLUMN dietary_fiber_per_100g  DOUBLE PRECISION,
    ADD COLUMN saturated_fat_per_100g  DOUBLE PRECISION,
    ADD COLUMN trans_fat_per_100g      DOUBLE PRECISION,
    ADD COLUMN cholesterol_per_100g_mg DOUBLE PRECISION,
    ADD COLUMN sodium_per_100g_mg      DOUBLE PRECISION;

-- ─────────────────────── food_entries (1회 섭취량 절댓값) ───────────────────────
ALTER TABLE food_entries
    ADD COLUMN sugars_g         DOUBLE PRECISION,
    ADD COLUMN dietary_fiber_g  DOUBLE PRECISION,
    ADD COLUMN saturated_fat_g  DOUBLE PRECISION,
    ADD COLUMN trans_fat_g      DOUBLE PRECISION,
    ADD COLUMN cholesterol_mg   DOUBLE PRECISION,
    ADD COLUMN sodium_mg        DOUBLE PRECISION;

-- ─────────────────────── diet_logs (식사 단위 합산) ───────────────────────
ALTER TABLE diet_logs
    ADD COLUMN total_sugars_g         DOUBLE PRECISION,
    ADD COLUMN total_dietary_fiber_g  DOUBLE PRECISION,
    ADD COLUMN total_saturated_fat_g  DOUBLE PRECISION,
    ADD COLUMN total_trans_fat_g      DOUBLE PRECISION,
    ADD COLUMN total_cholesterol_mg   DOUBLE PRECISION,
    ADD COLUMN total_sodium_mg        DOUBLE PRECISION;

-- ─────────────────────── meal_photo_analysis_items (AI 사진 분석 결과) ───────────────────────
ALTER TABLE meal_photo_analysis_items
    ADD COLUMN sugars_g         DOUBLE PRECISION,
    ADD COLUMN dietary_fiber_g  DOUBLE PRECISION,
    ADD COLUMN saturated_fat_g  DOUBLE PRECISION,
    ADD COLUMN trans_fat_g      DOUBLE PRECISION,
    ADD COLUMN cholesterol_mg   DOUBLE PRECISION,
    ADD COLUMN sodium_mg        DOUBLE PRECISION;
