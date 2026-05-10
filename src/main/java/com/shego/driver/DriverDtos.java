package com.shego.driver;

import com.shego.common.AdminApprovalStatus;
import com.shego.common.Gender;
import com.shego.common.KycStatus;
import com.shego.common.VehicleType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.LocalDate;
import java.util.UUID;

public class DriverDtos {
    public record SignupRequest(@NotBlank String fullName, @NotBlank String mobileNumber, String password,
                                @NotNull Gender gender, @NotNull LocalDate dateOfBirth, @NotBlank String address,
                                @NotBlank String drivingLicenseNumber, @NotNull VehicleType vehicleType,
                                @NotBlank String vehicleRegistrationNumber, @NotBlank String insuranceDetails,
                                String aadhaarNumber, String selfieStorageKey, String aadhaarStorageKey,
                                String licenseStorageKey, String vehicleDocumentStorageKey,
                                String insuranceDocumentStorageKey) {
    }

    public record LoginRequest(@NotBlank String mobileNumber, @NotBlank String password) {
    }

    public record UploadKycRequest(String aadhaarNumber, String selfieStorageKey, String aadhaarStorageKey,
                                   String licenseStorageKey, String vehicleDocumentStorageKey,
                                   String insuranceDocumentStorageKey) {
    }

    public record OnboardRequest(@NotBlank String licenseNumber, @NotNull VehicleType vehicleType,
                                 @NotBlank String vehicleRegistrationNumber, String insurancePolicyNumber, String model) {
    }

    public record AvailabilityRequest(boolean available, boolean online) {
    }

    public record LocationRequest(double latitude, double longitude) {
    }

    public record DriverResponse(UUID id, String fullName, VehicleType vehicleType, boolean available, boolean online,
                                 boolean adminApproved, KycStatus kycStatus, double averageRating, int completedRides) {
    }

    public record DriverProfileResponse(UUID id, String fullName, String mobileNumber, Gender gender, LocalDate dateOfBirth,
                                        int age, VehicleType vehicleType, String vehicleRegistrationNumber,
                                        String aadhaarLast4,
                                        KycStatus kycStatus, AdminApprovalStatus adminApprovalStatus, boolean available,
                                        boolean online) {
        public static DriverProfileResponse from(DriverProfile driver) {
            return new DriverProfileResponse(driver.getId(), driver.getUser().getFullName(), driver.getUser().getMobileNumber(),
                    driver.getGender(), driver.getDateOfBirth(), driver.getAge(), driver.getVehicleType(),
                    driver.getVehicleRegistrationNumber(), driver.getAadhaarLast4(), driver.getKycStatus(), driver.getAdminApprovalStatus(),
                    driver.isAvailable(), driver.isOnline());
        }
    }
}
