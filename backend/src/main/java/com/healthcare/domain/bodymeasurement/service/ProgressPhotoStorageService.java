package com.healthcare.domain.bodymeasurement.service;

import java.time.OffsetDateTime;

public interface ProgressPhotoStorageService {

    PresignedUpload generateUploadUrl(Long userId, String fileName, String contentType, long fileSizeBytes);

    String generateDownloadUrl(String storageKey);

    StoredObject getObject(String storageKey);

    void putObject(String storageKey, String contentType, byte[] bytes);

    ObjectMetadata getObjectMetadata(String storageKey);

    record PresignedUpload(String storageKey, String uploadUrl, OffsetDateTime expiresAt) {
    }

    record StoredObject(byte[] bytes, String contentType, long contentLength) {
    }

    record ObjectMetadata(String contentType, long contentLength) {
    }
}
