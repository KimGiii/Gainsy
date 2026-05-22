package com.healthcare.domain.diet.ai.dto;

/**
 * 영양표시기준 10종(앱 전체 표준).
 * AI 추정 응답의 items[].nutrition과 totalNutrition에서 공통 사용.
 */
public record NutritionFacts(
        Double caloriesKcal,
        Double carbohydrateG,
        Double sugarsG,
        Double dietaryFiberG,
        Double proteinG,
        Double fatG,
        Double saturatedFatG,
        Double transFatG,
        Double cholesterolMg,
        Double sodiumMg
) {
    public static NutritionFacts zero() {
        return new NutritionFacts(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    }
}
