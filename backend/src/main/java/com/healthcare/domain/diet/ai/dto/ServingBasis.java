package com.healthcare.domain.diet.ai.dto;

/**
 * AI 추정 영양성분의 산정 기준.
 * - PER_ITEM: 브랜드/프랜차이즈 메뉴 등 단위 음식 1개 전체
 * - PER_100G: 일반 식재료·요리명 (무게 미명시)
 * - CUSTOM_WEIGHT: 사용자가 명시한 무게 기준
 */
public enum ServingBasis {
    PER_ITEM, PER_100G, CUSTOM_WEIGHT
}
