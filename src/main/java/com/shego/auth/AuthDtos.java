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

    public record ForgotPasswordSendOtpRequest(@NotBlank String identifier) {
    }

    public record ForgotPasswordSendOtpResponse(String message, String devOtp) {
    }

    public record ForgotPasswordVerifyOtpRequest(@NotBlank String identifier, @NotBlank String otp) {
    }

    public record ForgotPasswordVerifyOtpResponse(boolean verified) {
    }

    public record ForgotPasswordResetRequest(@NotBlank String identifier, @NotBlank String otp, @NotBlank String newPassword) {
    }

    public record AuthResponse(String accessToken, String refreshToken) {
    }
}
