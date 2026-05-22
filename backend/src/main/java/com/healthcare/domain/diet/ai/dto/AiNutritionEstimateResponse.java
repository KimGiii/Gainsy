package com.healthcare.domain.diet.ai.dto;

import java.util.List;

/**
 * AI 텍스트 기반 영양성분 추정 응답.
 *
 * - isFood=true: items와 totalNutrition이 채워지고 error=null
 * - isFood=false: items=[], totalNutrition=null, error에 사유
 *
 * 클라이언트는 disclaimer를 사용자에게 노출하고, 사용자가 수정 후 저장하도록 한다.
 */
public record AiNutritionEstimateResponse(
        boolean isFood,
        String inputText,
        List<EstimatedItem> items,
        NutritionFacts totalNutrition,
        EstimationError error,
        String disclaimer,
        boolean aiEstimated
) {
    public static final String DISCLAIMER =
            "AI 추정값이며 실제 영양성분과 다를 수 있습니다. 수정 후 저장하세요.";

    public static AiNutritionEstimateResponse ok(String inputText,
                                                 List<EstimatedItem> items,
                                                 NutritionFacts totalNutrition) {
        return new AiNutritionEstimateResponse(
                true, inputText, items, totalNutrition, null, DISCLAIMER, true);
    }

    public static AiNutritionEstimateResponse notFood(String inputText) {
        return new AiNutritionEstimateResponse(
                false, inputText, List.of(), null,
                EstimationError.notFoodOrUnknown(), DISCLAIMER, true);
    }

    public static AiNutritionEstimateResponse unavailable(String inputText) {
        return new AiNutritionEstimateResponse(
                false, inputText, List.of(), null,
                EstimationError.aiUnavailable(), DISCLAIMER, true);
    }
}
