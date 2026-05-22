package com.healthcare.domain.diet.entity;

/**
 * DietLog 합산 영양소 10종(영양표시기준).
 * DietLog.update() 시그니처 단순화용 value object.
 */
public record DietLogNutritionTotals(
        Double totalCalories,
        Double totalCarbsG,
        Double totalSugarsG,
        Double totalDietaryFiberG,
        Double totalProteinG,
        Double totalFatG,
        Double totalSaturatedFatG,
        Double totalTransFatG,
        Double totalCholesterolMg,
        Double totalSodiumMg
) {}
