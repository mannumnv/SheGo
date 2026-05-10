package com.shego.guardian;

import com.shego.common.ApiResponse;
import com.shego.user.CurrentUserService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
public class GuardianController {
    private final GuardianService guardians;
    private final CurrentUserService currentUserService;

    public GuardianController(GuardianService guardians, CurrentUserService currentUserService) {
        this.guardians = guardians;
        this.currentUserService = currentUserService;
    }

    @PostMapping("/api/guardians")
    ApiResponse<GuardianDtos.GuardianResponse> add(@Valid @RequestBody GuardianDtos.UpsertRequest request) {
        return ApiResponse.ok("Guardian added", GuardianDtos.GuardianResponse.from(guardians.add(currentUserService.current(), request)));
    }

    @GetMapping("/api/guardians")
    ApiResponse<List<GuardianDtos.GuardianResponse>> list() {
        return ApiResponse.ok("Guardians", guardians.list(currentUserService.current()).stream().map(GuardianDtos.GuardianResponse::from).toList());
    }

    @DeleteMapping("/api/guardians/{id}")
    ApiResponse<Void> delete(@PathVariable UUID id) {
        guardians.delete(id);
        return ApiResponse.ok("Guardian deleted", null);
    }

    @PostMapping("/api/rides/{id}/share-live-location")
    ApiResponse<Void> share(@PathVariable UUID id) {
        guardians.share(id);
        return ApiResponse.ok("Live location sharing enabled", null);
    }

    @PostMapping("/api/trusted-drivers")
    ApiResponse<GuardianDtos.TrustedDriverResponse> addTrustedDriver(@RequestBody GuardianDtos.TrustedDriverRequest request) {
        return ApiResponse.ok("Trusted driver added",
                GuardianDtos.TrustedDriverResponse.from(guardians.addTrustedDriver(currentUserService.current(), request.driverId())));
    }

    @GetMapping("/api/trusted-drivers")
    ApiResponse<List<GuardianDtos.TrustedDriverResponse>> trustedDrivers() {
        return ApiResponse.ok("Trusted drivers",
                guardians.trustedDrivers(currentUserService.current()).stream().map(GuardianDtos.TrustedDriverResponse::from).toList());
    }
}
