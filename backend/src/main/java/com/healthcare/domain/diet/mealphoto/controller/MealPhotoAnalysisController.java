package com.healthcare.domain.diet.mealphoto.controller;

import com.healthcare.common.response.ApiResponse;
import com.healthcare.common.security.PremiumAccessGuard;
import com.healthcare.domain.diet.mealphoto.dto.*;
import com.healthcare.domain.diet.mealphoto.service.MealPhotoAnalysisService;
import com.healthcare.security.CurrentUserId;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/diet/photo-analyses")
@RequiredArgsConstructor
public class MealPhotoAnalysisController {

    private final MealPhotoAnalysisService mealPhotoAnalysisService;
    private final PremiumAccessGuard premiumAccessGuard;

    @PostMapping("/initiate")
    public ResponseEntity<ApiResponse<InitiateMealPhotoAnalysisResponse>> initiate(
            @CurrentUserId Long userId,
            @Valid @RequestBody InitiateMealPhotoAnalysisRequest request
    ) {
        premiumAccessGuard.assertPremium(userId);
        InitiateMealPhotoAnalysisResponse response = mealPhotoAnalysisService.initiate(userId, request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok("식단 사진 업로드 준비가 완료되었습니다.", response));
    }

    @PostMapping("/{id}/analyze")
    public ResponseEntity<ApiResponse<MealPhotoAnalysisResponse>> analyze(
            @CurrentUserId Long userId,
            @PathVariable Long id,
            @Valid @RequestBody AnalyzeMealPhotoRequest request
    ) {
        premiumAccessGuard.assertPremium(userId);
        MealPhotoAnalysisResponse response = mealPhotoAnalysisService.analyze(userId, id, request);
        return ResponseEntity.ok(ApiResponse.ok("식단 사진 분석 초안이 생성되었습니다.", response));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<MealPhotoAnalysisResponse>> get(
            @CurrentUserId Long userId,
            @PathVariable Long id
    ) {
        premiumAccessGuard.assertPremium(userId);
        MealPhotoAnalysisResponse response = mealPhotoAnalysisService.get(userId, id);
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @PostMapping("/{id}/confirm")
    public ResponseEntity<ApiResponse<ConfirmMealPhotoAnalysisResponse>> confirm(
            @CurrentUserId Long userId,
            @PathVariable Long id,
            @Valid @RequestBody ConfirmMealPhotoAnalysisRequest request
    ) {
        premiumAccessGuard.assertPremium(userId);
        ConfirmMealPhotoAnalysisResponse response = mealPhotoAnalysisService.confirm(userId, id, request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok("식단 사진 분석 결과가 식단 기록으로 저장되었습니다.", response));
    }
}
