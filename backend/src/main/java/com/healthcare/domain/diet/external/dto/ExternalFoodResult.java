package com.healthcare.domain.diet.external.dto;

import com.healthcare.domain.diet.entity.FoodCatalog.FoodCategory;
import lombok.Builder;
import lombok.Getter;
import lombok.extern.jackson.Jacksonized;

@Getter
@Builder
@Jacksonized
public class ExternalFoodResult {

    private final FoodDataSource source;
    private final String externalId;
    private final String name;
    private final String nameKo;
    private final String brand;
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

    public enum FoodDataSource {
        PUBLIC_FOOD_API, ALL
    }
}
