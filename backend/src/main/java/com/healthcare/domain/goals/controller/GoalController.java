package com.healthcare.domain.goals.controller;

import com.healthcare.common.response.ApiResponse;
import com.healthcare.common.web.PageRequests;
import com.healthcare.domain.goals.dto.*;
import com.healthcare.domain.goals.entity.Goal.GoalStatus;
import com.healthcare.domain.goals.service.GoalService;
import com.healthcare.security.CurrentUserId;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/goals")
@RequiredArgsConstructor
public class GoalController {

    private final GoalService goalService;

    @PostMapping
    public ResponseEntity<ApiResponse<GoalResponse>> createGoal(
            @CurrentUserId Long userId,
            @Valid @RequestBody CreateGoalRequest request) {
        GoalResponse response = goalService.createGoal(userId, request);
        return ResponseEntity.status(201)
                .body(ApiResponse.ok("목표가 생성되었습니다. 칼로리 및 영양소 목표가 업데이트되었습니다.", response));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<GoalListResponse>> listGoals(
            @CurrentUserId Long userId,
            @RequestParam(required = false) GoalStatus status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Pageable pageable = PageRequests.of(page, size);
        GoalListResponse response = goalService.listGoals(userId, status, pageable);
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<GoalResponse>> getGoal(
            @CurrentUserId Long userId,
            @PathVariable Long id) {
        GoalResponse response = goalService.getGoalById(userId, id);
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @PatchMapping("/{id}")
    public ResponseEntity<ApiResponse<GoalResponse>> updateGoal(
            @CurrentUserId Long userId,
            @PathVariable Long id,
            @RequestBody UpdateGoalRequest request) {
        GoalResponse response = goalService.updateGoal(userId, id, request);
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @GetMapping("/{id}/progress")
    public ResponseEntity<ApiResponse<GoalProgressResponse>> getGoalProgress(
            @CurrentUserId Long userId,
            @PathVariable Long id) {
        GoalProgressResponse response = goalService.getGoalProgress(userId, id);
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> abandonGoal(
            @CurrentUserId Long userId,
            @PathVariable Long id) {
        goalService.abandonGoal(userId, id);
        return ResponseEntity.ok(ApiResponse.ok("목표가 포기 처리되었습니다. 목표 히스토리에서 확인하실 수 있습니다."));
    }
}
