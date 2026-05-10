package com.shego.storage;

import jakarta.validation.constraints.NotBlank;

public class StorageDtos {
    public record UploadIntentRequest(@NotBlank String folder, @NotBlank String fileName, @NotBlank String contentType) {
    }

    public record UploadIntentResponse(String privateStorageKey, String uploadUrl, String method) {
    }

    public record DownloadIntentRequest(@NotBlank String privateStorageKey) {
    }

    public record DownloadIntentResponse(String privateStorageKey, String downloadUrl, int expiresInMinutes) {
    }
}
