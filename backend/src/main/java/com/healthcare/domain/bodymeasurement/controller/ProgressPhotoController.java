package com.healthcare.domain.bodymeasurement.controller;

import com.healthcare.common.response.ApiResponse;
import com.healthcare.common.web.PageRequests;
import com.healthcare.domain.bodymeasurement.dto.*;
import com.healthcare.domain.bodymeasurement.entity.ProgressPhoto.PhotoType;
import com.healthcare.domain.bodymeasurement.service.ProgressPhotoService;
import com.healthcare.security.CurrentUserId;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

@RestController
@RequestMapping("/api/v1/body-measurements/photos")
@RequiredArgsConstructor
public class ProgressPhotoController {

    private final ProgressPhotoService progressPhotoService;

    @PostMapping("/upload-url")
    public ResponseEntity<ApiResponse<InitiatePhotoUploadResponse>> createUploadUrl(
            @CurrentUserId Long userId,
            @Valid @RequestBody InitiatePhotoUploadRequest request) {
        InitiatePhotoUploadResponse response = progressPhotoService.initiateUpload(userId, request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok("업로드 URL이 생성되었습니다.", response));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<ProgressPhotoResponse>> registerPhoto(
            @CurrentUserId Long userId,
            @Valid @RequestBody CreateProgressPhotoRequest request) {
        ProgressPhotoResponse response = progressPhotoService.registerPhoto(userId, request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok("진행 사진 메타데이터가 저장되었습니다.", response));
    }

    @DeleteMapping("/{photoId}")
    public ResponseEntity<ApiResponse<Void>> deletePhoto(
            @CurrentUserId Long userId,
            @PathVariable Long photoId) {
        progressPhotoService.deletePhoto(userId, photoId);
        return ResponseEntity.ok(ApiResponse.ok("사진이 삭제되었습니다.", null));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<ProgressPhotoListResponse>> listPhotos(
            @CurrentUserId Long userId,
            @RequestParam(required = false) PhotoType photoType,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Pageable pageable = PageRequests.of(page, size, Sort.by("capturedAt").descending());
        ProgressPhotoListResponse response = progressPhotoService.listPhotos(userId, photoType, from, to, pageable);
        return ResponseEntity.ok(ApiResponse.ok(response));
    }
}
