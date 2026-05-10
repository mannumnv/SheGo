package com.shego.user;

import com.shego.common.AccountStatus;
import com.shego.common.Role;

import java.util.Set;
import java.util.UUID;

public class UserDtos {
    public record UserResponse(UUID id, String fullName, String mobileNumber, String email, Set<Role> roles,
                               AccountStatus accountStatus, boolean femaleVerified) {
        public static UserResponse from(User user) {
            return new UserResponse(user.getId(), user.getFullName(), user.getMobileNumber(), user.getEmail(),
                    user.getRoles(), user.getAccountStatus(), user.isFemaleVerified());
        }
    }

    public record UpdateProfileRequest(String fullName, String email) {
    }
}
