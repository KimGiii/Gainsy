package com.healthcare.domain.diet.ai.dto;

import com.healthcare.domain.diet.entity.FoodCatalog.FoodCategory;

/**
 * AI 추정 결과의 개별 음식 항목.
 * confidence는 "high"|"medium"|"low" 문자열을 0.9/0.6/0.3으로 정규화한 값.
 */
public record EstimatedItem(
        String name,
        String normalizedName,
        FoodCategory category,
        ServingBasis servingBasis,
        String servingDescription,
        Double estimatedWeightG,
        NutritionFacts nutrition,
        Double confidence,
        String estimationNote
) {}
