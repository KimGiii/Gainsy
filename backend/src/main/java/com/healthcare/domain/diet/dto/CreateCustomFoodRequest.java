package com.healthcare.domain.diet.dto;

import com.healthcare.domain.diet.entity.FoodCatalog.FoodCategory;
import jakarta.validation.constraints.*;
import lombok.*;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateCustomFoodRequest {

    @NotBlank(message = "식품명은 필수입니다.")
    @Size(min = 1, max = 100, message = "식품명은 1~100자 이내여야 합니다.")
    @Pattern(regexp = "^[^<>\"'&;]*$", message = "식품명에 허용되지 않는 문자가 포함되어 있습니다.")
    private String name;

    @Size(max = 100, message = "한국어 식품명은 100자 이내여야 합니다.")
    @Pattern(regexp = "^[^<>\"'&;]*$", message = "식품명에 허용되지 않는 문자가 포함되어 있습니다.")
    private String nameKo;

    @NotNull(message = "카테고리는 필수입니다.")
    private FoodCategory category;

    @NotNull(message = "칼로리는 필수입니다.")
    @PositiveOrZero(message = "칼로리는 0 이상이어야 합니다.")
    @DecimalMax(value = "9999", message = "칼로리는 9999 이하여야 합니다.")
    private Double caloriesPer100g;

    @PositiveOrZero(message = "단백질은 0 이상이어야 합니다.")
    @DecimalMax(value = "9999", message = "단백질은 9999 이하여야 합니다.")
    private Double proteinPer100g;

    @PositiveOrZero(message = "탄수화물은 0 이상이어야 합니다.")
    @DecimalMax(value = "9999", message = "탄수화물은 9999 이하여야 합니다.")
    private Double carbsPer100g;

    @PositiveOrZero(message = "지방은 0 이상이어야 합니다.")
    @DecimalMax(value = "9999", message = "지방은 9999 이하여야 합니다.")
    private Double fatPer100g;
}
