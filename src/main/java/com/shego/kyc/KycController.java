package com.shego.kyc;

import com.shego.common.ApiResponse;
import com.shego.user.CurrentUserService;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
public class KycController {
    private static final Logger log = LoggerFactory.getLogger(KycController.class);

    private final KycService kycService;
    private final CurrentUserService currentUserService;

    public KycController(KycService kycService, CurrentUserService currentUserService) {
        this.kycService = kycService;
        this.currentUserService = currentUserService;
    }

    @PostMapping("/api/kyc/upload")
    ApiResponse<KycDtos.KycResponse> upload(@Valid @RequestBody KycDtos.UploadRequest request) {
        return ApiResponse.ok("KYC uploaded", KycDtos.KycResponse.from(kycService.upload(currentUserService.current(), request)));
    }

    @GetMapping("/api/kyc/status")
    ApiResponse<List<KycDtos.KycResponse>> status() {
        return ApiResponse.ok("KYC status", kycService.status(currentUserService.current()).stream().map(KycDtos.KycResponse::from).toList());
    }

    @PreAuthorize("hasAnyRole('ADMIN','SUPPORT')")
    @GetMapping("/api/admin/kyc/pending")
    ApiResponse<List<KycDtos.KycResponse>> pending() {
        return ApiResponse.ok("Pending KYC", kycService.pending().stream().map(KycDtos.KycResponse::from).toList());
    }

    @PreAuthorize("hasAnyRole('ADMIN','SUPPORT')")
    @PostMapping("/api/admin/kyc/{id}/approve")
    ApiResponse<KycDtos.KycResponse> approve(@PathVariable UUID id) {
        log.debug("KycController entry: POST /api/admin/kyc/{id}/approve id={}", id);
        var response = KycDtos.KycResponse.from(kycService.approve(id));
        log.debug("KycController return: KYC approved id={}, status={}", response.id(), response.status());
        return ApiResponse.ok("KYC approved", response);
    }

    @PreAuthorize("hasAnyRole('ADMIN','SUPPORT')")
    @PostMapping("/api/admin/kyc/{id}/reject")
    ApiResponse<KycDtos.KycResponse> reject(@PathVariable UUID id, @RequestBody KycDtos.RejectRequest request) {
        log.debug("KycController entry: POST /api/admin/kyc/{id}/reject id={}", id);
        var response = KycDtos.KycResponse.from(kycService.reject(id, request.reason()));
        log.debug("KycController return: KYC rejected id={}, status={}", response.id(), response.status());
        return ApiResponse.ok("KYC rejected", response);
    }
}
