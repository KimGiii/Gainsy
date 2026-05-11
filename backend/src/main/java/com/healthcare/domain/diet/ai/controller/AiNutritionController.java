package com.healthcare.domain.diet.ai.controller;

import com.healthcare.common.response.ApiResponse;
import com.healthcare.domain.diet.ai.dto.AiNutritionEstimateRequest;
import com.healthcare.domain.diet.ai.dto.AiNutritionEstimateResponse;
import com.healthcare.domain.diet.ai.service.AiNutritionEstimationService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/diet")
public class AiNutritionController {

    private final ObjectProvider<AiNutritionEstimationService> estimationServiceProvider;

    public AiNutritionController(ObjectProvider<AiNutritionEstimationService> estimationServiceProvider) {
        this.estimationServiceProvider = estimationServiceProvider;
    }

    @PostMapping("/ai-estimate")
    public ResponseEntity<ApiResponse<AiNutritionEstimateResponse>> estimate(
            @Valid @RequestBody AiNutritionEstimateRequest request) {

        AiNutritionEstimationService service = estimationServiceProvider.getIfAvailable();
        if (service == null) {
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                    .body(ApiResponse.error("AI 추정 서비스가 비활성 상태입니다. OpenAI API 키를 설정하세요."));
        }

        try {
            AiNutritionEstimateResponse response = service.estimate(request.getFoodName());
            return ResponseEntity.ok(ApiResponse.ok(response));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("AI 영양 추정에 실패했습니다. 잠시 후 다시 시도해 주세요."));
        }
    }
}
