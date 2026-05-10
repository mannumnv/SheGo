package com.shego.kyc;

import com.shego.common.KycStatus;
import jakarta.validation.constraints.NotBlank;

import java.util.UUID;

public class KycDtos {
    public record UploadRequest(@NotBlank String documentType, @NotBlank String privateStorageKey, String maskedDocumentNumber) {
    }

    public record RejectRequest(String reason) {
    }

    public record KycResponse(UUID id, String documentType, KycStatus status, String rejectionReason) {
        static KycResponse from(KycDocument doc) {
            return new KycResponse(doc.getId(), doc.getDocumentType(), doc.getStatus(), doc.getRejectionReason());
        }
    }
}
