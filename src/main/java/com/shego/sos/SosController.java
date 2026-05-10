package com.shego.sos;

import com.shego.common.ApiResponse;
import com.shego.user.CurrentUserService;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
public class SosController {
    private final SosService sos;
    private final CurrentUserService currentUserService;

    public SosController(SosService sos, CurrentUserService currentUserService) {
        this.sos = sos;
        this.currentUserService = currentUserService;
    }

    @PostMapping("/api/sos/trigger")
    ApiResponse<SosDtos.SosResponse> trigger(@RequestBody SosDtos.TriggerRequest request) {
        return ApiResponse.ok("SOS triggered", SosDtos.SosResponse.from(sos.trigger(currentUserService.current(), request)));
    }

    @PreAuthorize("hasAnyRole('ADMIN','SUPPORT')")
    @PostMapping("/api/sos/{id}/resolve")
    ApiResponse<SosDtos.SosResponse> resolve(@PathVariable UUID id, @RequestBody SosDtos.ResolveRequest request) {
        return ApiResponse.ok("SOS resolved", SosDtos.SosResponse.from(sos.resolve(id, request.notes())));
    }

    @PreAuthorize("hasAnyRole('ADMIN','SUPPORT')")
    @GetMapping("/api/admin/sos/active")
    ApiResponse<List<SosDtos.SosResponse>> active() {
        return ApiResponse.ok("Active SOS alerts", sos.active().stream().map(SosDtos.SosResponse::from).toList());
    }
}
