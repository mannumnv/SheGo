package com.shego.rider;

import com.shego.common.AccountStatus;
import com.shego.common.Gender;
import com.shego.common.KycStatus;
import com.shego.common.RiderAgeCategory;
import com.shego.common.VerificationType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.LocalDate;
import java.util.UUID;

public class RiderDtos {
    public record SignupRequest(@NotBlank String fullName, @NotBlank String mobileNumber, String password,
                                @NotNull Gender gender, @NotNull LocalDate dateOfBirth, String address,
                                String profilePhotoStorageKey, String emergencyContact, String guardianName,
                                String guardianRelationship, String guardianMobileNumber, String guardianAadhaarNumber,
                                String riderAadhaarNumber, boolean guardianConsent) {
    }

    public record LoginRequest(@NotBlank String mobileNumber, @NotBlank String password) {
    }

    public record GuardianVerificationRequest(@NotBlank String guardianAadhaarNumber, @NotBlank String guardianMobileNumber,
                                              @NotBlank String guardianRelationship, boolean guardianConsent) {
    }

    public record RiderProfileResponse(UUID id, String fullName, String mobileNumber, Gender gender, LocalDate dateOfBirth,
                                       int age, RiderAgeCategory ageCategory, VerificationType verificationType,
                                       KycStatus kycStatus, AccountStatus accountStatus, String guardianRelationship,
                                       String guardianMobileNumber, String guardianAadhaarLast4, String riderAadhaarLast4,
                                       boolean guardianConsent) {
        public static RiderProfileResponse from(RiderProfile profile) {
            return new RiderProfileResponse(profile.getId(), profile.getUser().getFullName(), profile.getUser().getMobileNumber(),
                    profile.getRiderGender(), profile.getRiderDateOfBirth(), profile.getRiderAge(),
                    profile.getRiderAgeCategory(), profile.getVerificationType(), profile.getKycStatus(),
                    profile.getUser().getAccountStatus(), profile.getGuardianRelationship(),
                    profile.getGuardianMobileNumber(), profile.getGuardianAadhaarLast4(),
                    profile.getRiderAadhaarLast4(), profile.isGuardianConsent());
        }
    }
}
