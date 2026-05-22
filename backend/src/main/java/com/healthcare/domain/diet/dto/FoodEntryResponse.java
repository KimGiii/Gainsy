package com.healthcare.domain.diet.dto;

import com.healthcare.domain.diet.entity.FoodCatalog.FoodCategory;
import com.healthcare.domain.diet.entity.FoodEntry;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class FoodEntryResponse {

    private final Long id;
    private final Long foodCatalogId;
    private final String foodName;
    private final String foodNameKo;
    private final FoodCategory category;
    private final Double servingG;
    private final Double calories;
    private final Double proteinG;
    private final Double carbsG;
    private final Double fatG;
    private final Double sugarsG;
    private final Double dietaryFiberG;
    private final Double saturatedFatG;
    private final Double transFatG;
    private final Double cholesterolMg;
    private final Double sodiumMg;
    private final String notes;

    public static FoodEntryResponse from(FoodEntry entry, String foodName, String foodNameKo,
            FoodCategory category) {
        return FoodEntryResponse.builder()
                .id(entry.getId())
                .foodCatalogId(entry.getFoodCatalogId())
                .foodName(foodName)
                .foodNameKo(foodNameKo)
                .category(category)
                .servingG(entry.getServingG())
                .calories(entry.getCalories())
                .proteinG(entry.getProteinG())
                .carbsG(entry.getCarbsG())
                .fatG(entry.getFatG())
                .sugarsG(entry.getSugarsG())
                .dietaryFiberG(entry.getDietaryFiberG())
                .saturatedFatG(entry.getSaturatedFatG())
                .transFatG(entry.getTransFatG())
                .cholesterolMg(entry.getCholesterolMg())
                .sodiumMg(entry.getSodiumMg())
                .notes(entry.getNotes())
                .build();
    }
}
