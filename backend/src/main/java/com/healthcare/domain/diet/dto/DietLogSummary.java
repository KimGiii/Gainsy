package com.healthcare.domain.diet.dto;

import com.healthcare.domain.diet.entity.DietLog;
import com.healthcare.domain.diet.entity.DietLog.MealType;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;

@Getter
@Builder
public class DietLogSummary {

    private final Long dietLogId;
    private final LocalDate logDate;
    private final MealType mealType;
    private final Double totalCalories;
    private final Double totalProteinG;
    private final Double totalCarbsG;
    private final Double totalFatG;
    private final Double totalSugarsG;
    private final Double totalDietaryFiberG;
    private final Double totalSaturatedFatG;
    private final Double totalTransFatG;
    private final Double totalCholesterolMg;
    private final Double totalSodiumMg;

    public static DietLogSummary from(DietLog log) {
        return DietLogSummary.builder()
                .dietLogId(log.getId())
                .logDate(log.getLogDate())
                .mealType(log.getMealType())
                .totalCalories(log.getTotalCalories())
                .totalProteinG(log.getTotalProteinG())
                .totalCarbsG(log.getTotalCarbsG())
                .totalFatG(log.getTotalFatG())
                .totalSugarsG(log.getTotalSugarsG())
                .totalDietaryFiberG(log.getTotalDietaryFiberG())
                .totalSaturatedFatG(log.getTotalSaturatedFatG())
                .totalTransFatG(log.getTotalTransFatG())
                .totalCholesterolMg(log.getTotalCholesterolMg())
                .totalSodiumMg(log.getTotalSodiumMg())
                .build();
    }
}
