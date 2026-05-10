package com.shego.user;

import com.shego.common.ApiResponse;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/users")
public class UserController {
    private final CurrentUserService currentUserService;
    private final UserRepository users;

    public UserController(CurrentUserService currentUserService, UserRepository users) {
        this.currentUserService = currentUserService;
        this.users = users;
    }

    @GetMapping("/me")
    ApiResponse<UserDtos.UserResponse> me() {
        return ApiResponse.ok("Profile", UserDtos.UserResponse.from(currentUserService.current()));
    }

    @PutMapping("/me")
    ApiResponse<UserDtos.UserResponse> update(@RequestBody UserDtos.UpdateProfileRequest request) {
        User user = currentUserService.current();
        if (request.fullName() != null) user.setFullName(request.fullName());
        if (request.email() != null) user.setEmail(request.email());
        return ApiResponse.ok("Profile updated", UserDtos.UserResponse.from(users.save(user)));
    }

    @DeleteMapping("/me")
    ApiResponse<Void> delete() {
        User user = currentUserService.current();
        user.setAccountStatus(com.shego.common.AccountStatus.BLOCKED);
        users.save(user);
        return ApiResponse.ok("Account deactivated", null);
    }
}
