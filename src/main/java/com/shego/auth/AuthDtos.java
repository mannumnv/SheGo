package com.shego.auth;

import com.shego.common.Role;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;

import java.util.Set;

public class AuthDtos {
    public record RegisterRequest(@NotBlank String fullName, @NotBlank String mobileNumber, String email,
                                  String password, @NotEmpty Set<Role> roles) {
    }

    public record LoginRequest(@NotBlank String mobileNumber, @NotBlank String password) {
    }

    public record OtpRequest(@NotBlank String mobileNumber) {
    }

    public record OtpVerifyRequest(@NotBlank String mobileNumber, @NotBlank String otp) {
    }

    public record RefreshTokenRequest(@NotBlank String refreshToken) {
    }

    public record AuthResponse(String accessToken, String refreshToken) {
    }
}
