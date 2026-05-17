package com.shego.rider;

import com.shego.auth.AuthDtos;
import com.shego.common.ApiResponse;
import com.shego.user.CurrentUserService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/riders")
public class RiderController {
    private final RiderService riders;
    private final CurrentUserService currentUserService;

    public RiderController(RiderService riders, CurrentUserService currentUserService) {
        this.riders = riders;
        this.currentUserService = currentUserService;
    }

    @PostMapping("/signup")
    ApiResponse<AuthDtos.AuthResponse> signup(@Valid @RequestBody RiderDtos.SignupRequest request) {
        return ApiResponse.ok("Rider signup completed", riders.signup(request));
    }

    @PostMapping("/login")
    ApiResponse<AuthDtos.AuthResponse> login(@Valid @RequestBody RiderDtos.LoginRequest request) {
        return ApiResponse.ok("Rider logged in", riders.login(request));
    }

    @PostMapping("/verify-guardian")
    ApiResponse<RiderDtos.RiderProfileResponse> verifyGuardian(@Valid @RequestBody RiderDtos.GuardianVerificationRequest request) {
        return ApiResponse.ok("Guardian verification submitted",
                RiderDtos.RiderProfileResponse.from(riders.verifyGuardian(currentUserService.current(), request)));
    }

    @GetMapping("/profile")
    ApiResponse<RiderDtos.RiderProfileResponse> profile() {
        return ApiResponse.ok("Rider profile", RiderDtos.RiderProfileResponse.from(riders.profile(currentUserService.current())));
    }

    @PutMapping("/active")
    ApiResponse<RiderDtos.RiderProfileResponse> active(@RequestBody RiderDtos.ActiveRequest request) {
        return ApiResponse.ok("Rider active status updated",
                RiderDtos.RiderProfileResponse.from(riders.active(currentUserService.current(), request)));
    }
}
