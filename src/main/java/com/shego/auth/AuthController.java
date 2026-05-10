package com.shego.auth;

import com.shego.common.ApiResponse;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/auth")
public class AuthController {
    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/register")
    ApiResponse<AuthDtos.AuthResponse> register(@Valid @RequestBody AuthDtos.RegisterRequest request) {
        return ApiResponse.ok("Registered", authService.register(request));
    }

    @PostMapping("/login")
    ApiResponse<AuthDtos.AuthResponse> login(@Valid @RequestBody AuthDtos.LoginRequest request) {
        return ApiResponse.ok("Logged in", authService.login(request));
    }

    @PostMapping("/otp/send")
    ApiResponse<Void> sendOtp(@Valid @RequestBody AuthDtos.OtpRequest request) {
        authService.sendOtp(request);
        return ApiResponse.ok("OTP sent", null);
    }

    @PostMapping("/otp/verify")
    ApiResponse<AuthDtos.AuthResponse> verifyOtp(@Valid @RequestBody AuthDtos.OtpVerifyRequest request) {
        return ApiResponse.ok("OTP verified", authService.verifyOtp(request));
    }

    @PostMapping("/refresh-token")
    ApiResponse<AuthDtos.AuthResponse> refresh(@Valid @RequestBody AuthDtos.RefreshTokenRequest request) {
        return ApiResponse.ok("Token refreshed", authService.refresh(request));
    }
}
