package com.healthcare.domain.diet.controller;

import com.healthcare.common.response.ApiResponse;
import com.healthcare.domain.diet.dto.*;
import com.healthcare.domain.diet.entity.FoodCatalog.FoodCategory;
import com.healthcare.domain.diet.service.FoodCatalogService;
import com.healthcare.security.CurrentUserId;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/diet/catalog")
@RequiredArgsConstructor
public class FoodCatalogController {

    private final FoodCatalogService foodCatalogService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<FoodCatalogResponse>>> searchFoods(
            @RequestParam(required = false) String query,
            @RequestParam(required = false) FoodCategory category,
            @RequestParam(defaultValue = "false") boolean customOnly) {
        List<FoodCatalogResponse> response = foodCatalogService.searchFoods(
                FoodSearchParams.of(query, category, customOnly));
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<FoodCatalogResponse>> createCustomFood(
            @CurrentUserId Long userId,
            @Valid @RequestBody CreateCustomFoodRequest request) {
        FoodCatalogResponse response = foodCatalogService.createCustomFood(userId, request);
        return ResponseEntity.status(201).body(ApiResponse.ok("커스텀 식품이 등록되었습니다.", response));
    }
}
