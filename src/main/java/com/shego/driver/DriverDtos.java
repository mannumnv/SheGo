package com.shego.driver;

import com.shego.common.AdminApprovalStatus;
import com.shego.common.DriverVerificationStatus;
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
                                String aadhaarNumber, String profilePhotoStorageKey, String selfieStorageKey,
                                String aadhaarStorageKey, String licenseStorageKey, String vehicleDocumentStorageKey,
                                String insuranceDocumentStorageKey) {
    }

    public record LoginRequest(@NotBlank String mobileNumber, @NotBlank String password) {
    }

    public record UploadKycRequest(String aadhaarNumber, String profilePhotoStorageKey, String selfieStorageKey,
                                   String aadhaarStorageKey, String licenseStorageKey, String vehicleDocumentStorageKey,
                                   String insuranceDocumentStorageKey, String profilePhotoData, String aadhaarDocumentData,
                                   String licenseDocumentData, String vehicleDocumentData, String insuranceDocumentData) {
    }

    public record VerificationStatusResponse(UUID driverId, DriverVerificationStatus verificationStatus,
                                             String rejectionReason, boolean documentsComplete,
                                             boolean canGoActive) {
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
                                        int age, String address, VehicleType vehicleType, String vehicleRegistrationNumber,
                                        String insuranceDetails, String aadhaarLast4, String profilePhotoStorageKey,
                                        String selfieStorageKey, String aadhaarStorageKey, String licenseStorageKey,
                                        String vehicleDocumentStorageKey, String insuranceDocumentStorageKey,
                                        boolean profilePhotoSubmitted, boolean aadhaarDocumentSubmitted,
                                        boolean licenseDocumentSubmitted, boolean vehicleDocumentSubmitted,
                                        boolean insuranceDocumentSubmitted, DriverVerificationStatus verificationStatus,
                                        String verificationRejectionReason, boolean documentsComplete,
                                        KycStatus kycStatus, AdminApprovalStatus adminApprovalStatus, boolean available,
                                        boolean online) {
        public static DriverProfileResponse from(DriverProfile driver) {
            return new DriverProfileResponse(driver.getId(), driver.getUser().getFullName(), driver.getUser().getMobileNumber(),
                    driver.getGender(), driver.getDateOfBirth(), driver.getAge(), driver.getAddress(), driver.getVehicleType(),
                    driver.getVehicleRegistrationNumber(), driver.getInsuranceDetails(), driver.getAadhaarLast4(),
                    driver.getProfilePhotoStorageKey(), driver.getSelfieStorageKey(), driver.getAadhaarStorageKey(),
                    driver.getLicenseStorageKey(), driver.getVehicleDocumentStorageKey(), driver.getInsuranceDocumentStorageKey(),
                    hasValue(driver.getProfilePhotoStorageKey()) || hasValue(driver.getProfilePhotoData()),
                    hasValue(driver.getAadhaarStorageKey()) || hasValue(driver.getAadhaarDocumentData()),
                    hasValue(driver.getLicenseStorageKey()) || hasValue(driver.getLicenseDocumentData()),
                    hasValue(driver.getVehicleDocumentStorageKey()) || hasValue(driver.getVehicleDocumentData()),
                    hasValue(driver.getInsuranceDocumentStorageKey()) || hasValue(driver.getInsuranceDocumentData()),
                    driver.getVerificationStatus(), driver.getVerificationRejectionReason(), documentsComplete(driver),
                    driver.getKycStatus(), driver.getAdminApprovalStatus(), driver.isAvailable(), driver.isOnline());
        }

        private static boolean documentsComplete(DriverProfile driver) {
            return (hasValue(driver.getProfilePhotoStorageKey()) || hasValue(driver.getProfilePhotoData()))
                    && (hasValue(driver.getAadhaarStorageKey()) || hasValue(driver.getAadhaarDocumentData()))
                    && (hasValue(driver.getLicenseStorageKey()) || hasValue(driver.getLicenseDocumentData()))
                    && (hasValue(driver.getVehicleDocumentStorageKey()) || hasValue(driver.getVehicleDocumentData()))
                    && (hasValue(driver.getInsuranceDocumentStorageKey()) || hasValue(driver.getInsuranceDocumentData()));
        }

        private static boolean hasValue(String value) {
            return value != null && !value.isBlank();
        }
    }
}
