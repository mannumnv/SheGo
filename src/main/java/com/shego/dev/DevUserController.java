package com.shego.dev;

import com.shego.common.ApiResponse;
import com.shego.exception.BusinessException;
import com.shego.user.UserRepository;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import org.springframework.context.annotation.Profile;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
@Profile({"local", "dev"})
public class DevUserController {
    private final UserRepository users;
    private final PasswordEncoder passwordEncoder;

    public DevUserController(UserRepository users, PasswordEncoder passwordEncoder) {
        this.users = users;
        this.passwordEncoder = passwordEncoder;
    }

    @PostMapping("/api/dev/users/reset-password")
    ApiResponse<Void> resetPassword(@Valid @RequestBody ResetPasswordRequest request) {
        var user = users.findByMobileNumber(request.mobileNumber())
                .orElseThrow(() -> new BusinessException("User not found"));
        user.setPasswordHash(passwordEncoder.encode(request.newPassword()));
        users.save(user);
        return ApiResponse.ok("Password reset for local/dev", null);
    }

    public record ResetPasswordRequest(@NotBlank String mobileNumber, @NotBlank String newPassword) {
    }
}
