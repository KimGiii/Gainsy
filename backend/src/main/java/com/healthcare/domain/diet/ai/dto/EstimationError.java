package com.healthcare.domain.diet.ai.dto;

/**
 * AI 추정 실패/판단 불가 응답.
 * - NOT_FOOD_OR_UNKNOWN: 입력이 음식이 아니거나 판단 불가
 * - AI_UNAVAILABLE: AI API 호출 자체 실패
 */
public record EstimationError(String code, String message) {

    public static EstimationError notFoodOrUnknown() {
        return new EstimationError("NOT_FOOD_OR_UNKNOWN",
                "입력값에서 음식 또는 식품을 판단할 수 없습니다.");
    }

    public static EstimationError aiUnavailable() {
        return new EstimationError("AI_UNAVAILABLE",
                "AI 추정 서비스를 일시적으로 사용할 수 없습니다. 잠시 후 다시 시도해 주세요.");
    }
}
