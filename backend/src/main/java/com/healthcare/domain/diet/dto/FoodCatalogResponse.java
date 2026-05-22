package com.healthcare.domain.diet.dto;

import com.healthcare.domain.diet.entity.FoodCatalog;
import com.healthcare.domain.diet.entity.FoodCatalog.FoodCategory;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class FoodCatalogResponse {

    private final Long id;
    private final String name;
    private final String nameKo;
    private final FoodCategory category;
    private final Double caloriesPer100g;
    private final Double proteinPer100g;
    private final Double carbsPer100g;
    private final Double fatPer100g;
    private final Double sugarsPer100g;
    private final Double dietaryFiberPer100g;
    private final Double saturatedFatPer100g;
    private final Double transFatPer100g;
    private final Double cholesterolPer100gMg;
    private final Double sodiumPer100gMg;
    private final boolean custom;
    private final long usageCount;
    private final Long createdByUserId;

    public static FoodCatalogResponse from(FoodCatalog food) {
        return FoodCatalogResponse.builder()
                .id(food.getId())
                .name(food.getName())
                .nameKo(food.getNameKo())
                .category(food.getCategory())
                .caloriesPer100g(food.getCaloriesPer100g())
                .proteinPer100g(food.getProteinPer100g())
                .carbsPer100g(food.getCarbsPer100g())
                .fatPer100g(food.getFatPer100g())
                .sugarsPer100g(food.getSugarsPer100g())
                .dietaryFiberPer100g(food.getDietaryFiberPer100g())
                .saturatedFatPer100g(food.getSaturatedFatPer100g())
                .transFatPer100g(food.getTransFatPer100g())
                .cholesterolPer100gMg(food.getCholesterolPer100gMg())
                .sodiumPer100gMg(food.getSodiumPer100gMg())
                .custom(food.getIsCustom())
                .usageCount(food.getUsageCount() != null ? food.getUsageCount() : 0L)
                .createdByUserId(food.getCreatedByUserId())
                .build();
    }
}
