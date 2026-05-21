package com.healthcare.domain.exercise.controller;

import com.healthcare.common.response.ApiResponse;
import com.healthcare.common.web.PageRequests;
import com.healthcare.domain.exercise.dto.*;
import com.healthcare.domain.exercise.service.ExerciseSessionService;
import com.healthcare.security.CurrentUserId;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

@RestController
@RequestMapping("/api/v1/exercise/sessions")
@RequiredArgsConstructor
public class ExerciseSessionController {

    private final ExerciseSessionService sessionService;

    @PostMapping
    public ResponseEntity<ApiResponse<CreateSessionResponse>> createSession(
            @CurrentUserId Long userId,
            @Valid @RequestBody CreateSessionRequest request) {
        CreateSessionResponse response = sessionService.createSession(userId, request);

        String message = response.getNewPersonalRecords().isEmpty()
                ? "운동 세션이 저장되었습니다."
                : "운동 세션이 저장되었습니다. 새로운 개인 최고 기록 " + response.getNewPersonalRecords().size() + "개!";

        return ResponseEntity.status(201).body(ApiResponse.ok(message, response));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<SessionListResponse>> listSessions(
            @CurrentUserId Long userId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        Pageable pageable = PageRequests.of(page, size);
        SessionListResponse response = sessionService.listSessions(userId, from, to, pageable);
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<SessionDetailResponse>> getSession(
            @CurrentUserId Long userId,
            @PathVariable Long id) {
        SessionDetailResponse response = sessionService.getSessionById(userId, id);
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteSession(
            @CurrentUserId Long userId,
            @PathVariable Long id) {
        sessionService.deleteSession(userId, id);
        return ResponseEntity.ok(ApiResponse.ok("운동 세션이 삭제되었습니다."));
    }
}
