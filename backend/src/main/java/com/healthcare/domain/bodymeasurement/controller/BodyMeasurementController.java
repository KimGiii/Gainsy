package com.healthcare.domain.bodymeasurement.controller;

import com.healthcare.common.response.ApiResponse;
import com.healthcare.domain.bodymeasurement.dto.*;
import com.healthcare.domain.bodymeasurement.service.BodyMeasurementService;
import com.healthcare.security.CurrentUserId;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/v1/body-measurements")
@RequiredArgsConstructor
public class BodyMeasurementController {

    private final BodyMeasurementService measurementService;

    @PostMapping
    public ResponseEntity<ApiResponse<MeasurementResponse>> createMeasurement(
            @CurrentUserId Long userId,
            @Valid @RequestBody CreateMeasurementRequest request) {
        MeasurementResponse response = measurementService.createMeasurement(userId, request);
        return ResponseEntity.status(201).body(ApiResponse.ok("신체 측정 기록이 저장되었습니다.", response));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<MeasurementListResponse>> listMeasurements(
            @CurrentUserId Long userId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by("measuredAt").descending());
        MeasurementListResponse response = measurementService.listMeasurements(userId, pageable);
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @GetMapping("/range")
    public ResponseEntity<ApiResponse<List<MeasurementResponse>>> listByDateRange(
            @CurrentUserId Long userId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        List<MeasurementResponse> response = measurementService.listMeasurementsByDateRange(userId, from, to);
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @GetMapping("/latest")
    public ResponseEntity<ApiResponse<MeasurementResponse>> getLatestMeasurement(
            @CurrentUserId Long userId) {
        MeasurementResponse response = measurementService.getLatestMeasurement(userId);
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @GetMapping("/at-or-before")
    public ResponseEntity<ApiResponse<MeasurementResponse>> getMeasurementAtOrBefore(
            @CurrentUserId Long userId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        MeasurementResponse response = measurementService.getMeasurementAtOrBefore(userId, date);
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<MeasurementResponse>> getMeasurement(
            @CurrentUserId Long userId,
            @PathVariable Long id) {
        MeasurementResponse response = measurementService.getMeasurementById(userId, id);
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @PatchMapping("/{id}")
    public ResponseEntity<ApiResponse<MeasurementResponse>> updateMeasurement(
            @CurrentUserId Long userId,
            @PathVariable Long id,
            @Valid @RequestBody UpdateMeasurementRequest request) {
        MeasurementResponse response = measurementService.updateMeasurement(userId, id, request);
        return ResponseEntity.ok(ApiResponse.ok("신체 측정 기록이 수정되었습니다.", response));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteMeasurement(
            @CurrentUserId Long userId,
            @PathVariable Long id) {
        measurementService.deleteMeasurement(userId, id);
        return ResponseEntity.ok(ApiResponse.ok("신체 측정 기록이 삭제되었습니다."));
    }
}
