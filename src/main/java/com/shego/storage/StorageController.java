package com.shego.storage;

import com.shego.common.ApiResponse;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class StorageController {
    private final StorageService storage;

    public StorageController(StorageService storage) {
        this.storage = storage;
    }

    @PostMapping("/api/storage/upload-intent")
    ApiResponse<StorageDtos.UploadIntentResponse> uploadIntent(@Valid @RequestBody StorageDtos.UploadIntentRequest request) {
        return ApiResponse.ok("Upload intent created", storage.uploadIntent(request));
    }

    @PreAuthorize("hasAnyRole('ADMIN','SUPPORT')")
    @PostMapping("/api/storage/download-intent")
    ApiResponse<StorageDtos.DownloadIntentResponse> downloadIntent(@Valid @RequestBody StorageDtos.DownloadIntentRequest request) {
        return ApiResponse.ok("Temporary download intent created", storage.downloadIntent(request));
    }
}
