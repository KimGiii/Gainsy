package com.healthcare.domain.exercise.controller;

import com.healthcare.common.response.ApiResponse;
import com.healthcare.domain.exercise.dto.CatalogSearchParams;
import com.healthcare.domain.exercise.dto.CreateCustomExerciseRequest;
import com.healthcare.domain.exercise.dto.ExerciseCatalogResponse;
import com.healthcare.domain.exercise.entity.ExerciseCatalog.ExerciseType;
import com.healthcare.domain.exercise.entity.ExerciseCatalog.MuscleGroup;
import com.healthcare.domain.exercise.service.ExerciseCatalogService;
import com.healthcare.security.CurrentUserId;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/exercise/catalog")
@RequiredArgsConstructor
public class ExerciseCatalogController {

    private final ExerciseCatalogService catalogService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<ExerciseCatalogResponse>>> searchCatalog(
            @CurrentUserId Long userId,
            @RequestParam(required = false) String query,
            @RequestParam(required = false) ExerciseType exerciseType,
            @RequestParam(required = false) MuscleGroup muscleGroup,
            @RequestParam(defaultValue = "false") boolean customOnly) {
        CatalogSearchParams params = CatalogSearchParams.of(query, exerciseType, muscleGroup, customOnly);
        List<ExerciseCatalogResponse> result = catalogService.searchCatalog(userId, params);
        return ResponseEntity.ok(ApiResponse.ok(result));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<ExerciseCatalogResponse>> createCustomExercise(
            @CurrentUserId Long userId,
            @Valid @RequestBody CreateCustomExerciseRequest request) {
        ExerciseCatalogResponse response = catalogService.createCustomExercise(userId, request);
        return ResponseEntity.status(201).body(ApiResponse.ok("커스텀 운동이 등록되었습니다.", response));
    }
}
