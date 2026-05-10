package com.shego.storage;

import com.shego.exception.BusinessException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;
import software.amazon.awssdk.services.s3.presigner.model.PutObjectPresignRequest;

import java.time.Instant;
import java.time.Duration;
import java.util.Set;

@Service
public class StorageService {
    private static final Set<String> ALLOWED_FOLDERS = Set.of("kyc", "profile", "sos");
    private final String bucket;
    private final S3Presigner presigner;

    public StorageService(@Value("${shego.storage.s3-bucket}") String bucket, S3Presigner presigner) {
        this.bucket = bucket;
        this.presigner = presigner;
    }

    public StorageDtos.UploadIntentResponse uploadIntent(StorageDtos.UploadIntentRequest request) {
        if (!ALLOWED_FOLDERS.contains(request.folder())) {
            throw new BusinessException("Unsupported upload folder");
        }
        if (!request.contentType().startsWith("image/") && !request.contentType().equals("application/pdf")) {
            throw new BusinessException("Only images or PDF files are allowed");
        }
        String safeName = request.fileName().replaceAll("[^a-zA-Z0-9._-]", "_");
        String key = request.folder() + "/" + Instant.now().toEpochMilli() + "-" + safeName;
        PutObjectRequest putObjectRequest = PutObjectRequest.builder()
                .bucket(bucket)
                .key(key)
                .contentType(request.contentType())
                .build();
        PutObjectPresignRequest presignRequest = PutObjectPresignRequest.builder()
                .signatureDuration(Duration.ofMinutes(10))
                .putObjectRequest(putObjectRequest)
                .build();
        return new StorageDtos.UploadIntentResponse(key, presigner.presignPutObject(presignRequest).url().toString(), "PUT");
    }

    public StorageDtos.DownloadIntentResponse downloadIntent(StorageDtos.DownloadIntentRequest request) {
        String key = request.privateStorageKey();
        if (key.contains("..") || key.startsWith("/") || ALLOWED_FOLDERS.stream().noneMatch(folder -> key.startsWith(folder + "/"))) {
            throw new BusinessException("Unsupported storage key");
        }
        GetObjectRequest getObjectRequest = GetObjectRequest.builder()
                .bucket(bucket)
                .key(key)
                .build();
        GetObjectPresignRequest presignRequest = GetObjectPresignRequest.builder()
                .signatureDuration(Duration.ofMinutes(10))
                .getObjectRequest(getObjectRequest)
                .build();
        return new StorageDtos.DownloadIntentResponse(key, presigner.presignGetObject(presignRequest).url().toString(), 10);
    }
}
