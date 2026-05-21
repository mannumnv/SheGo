package com.shego.admin;

import com.shego.common.AdminApprovalStatus;
import com.shego.common.DriverVerificationStatus;
import com.shego.common.Gender;
import com.shego.common.KycStatus;
import com.shego.common.VehicleType;
import com.shego.driver.DriverProfile;
import com.shego.driver.DriverProfileRepository;
import io.swagger.v3.oas.annotations.media.Schema;

import java.time.Instant;
import java.util.UUID;

public class AdminDtos {
    @Schema(name = "RiderApprovalResponse", description = "Admin rider approval result for rider_profile approval.")
    public record RiderApprovalResponse(
            @Schema(example = "3f6c7b7a-4d5b-4bd5-8c6a-2a7f8b7d9c10") UUID id,
            @Schema(example = "APPROVED") KycStatus kycStatus,
            @Schema(example = "ACTIVE") com.shego.common.AccountStatus accountStatus,
            @Schema(example = "SELF_AADHAAR") com.shego.common.VerificationType verificationType
    ) {
    }

    @Schema(name = "DriverApprovalResponse", description = "Admin driver approval result without exposing KYC documents or Aadhaar values.")
    public record DriverApprovalResponse(
            @Schema(example = "3f6c7b7a-4d5b-4bd5-8c6a-2a7f8b7d9c10") UUID driverId,
            @Schema(example = "APPROVED") KycStatus kycStatus,
            @Schema(example = "APPROVED") AdminApprovalStatus adminApprovalStatus,
            @Schema(example = "true") boolean adminApproved
    ) {
    }

    @Schema(name = "AdminDriverResponse", description = "Admin driver list/detail row with safe profile, vehicle, document, and status metadata.")
    public record AdminDriverResponse(
            UUID driverId,
            UUID userId,
            String fullName,
            String mobileNumber,
            String email,
            Gender gender,
            int age,
            String aadhaarVerificationStatus,
            String drivingLicenseStatus,
            VehicleType vehicleType,
            String vehicleRegistrationNumber,
            String insuranceStatus,
            String documentSubmissionStatus,
            String driverApprovalStatus,
            String profileActiveStatus,
            DriverVerificationStatus verificationStatus,
            String verificationRejectionReason,
            KycStatus kycStatus,
            AdminApprovalStatus adminApprovalStatus,
            boolean adminApproved,
            boolean available,
            boolean online,
            String aadhaarLast4,
            String profilePhotoStorageKey,
            String aadhaarStorageKey,
            String licenseStorageKey,
            String vehicleDocumentStorageKey,
            String insuranceDocumentStorageKey,
            String profilePhotoData,
            String aadhaarDocumentData,
            String licenseDocumentData,
            String vehicleDocumentData,
            String insuranceDocumentData,
            Instant signupDate,
            Instant lastUpdatedDate
    ) {
        public static AdminDriverResponse from(DriverProfile driver) {
            boolean profilePhotoSubmitted = hasValue(driver.getProfilePhotoStorageKey()) || hasValue(driver.getProfilePhotoData());
            boolean aadhaarSubmitted = hasValue(driver.getAadhaarStorageKey()) || hasValue(driver.getAadhaarDocumentData());
            boolean licenseSubmitted = hasValue(driver.getLicenseStorageKey()) || hasValue(driver.getLicenseDocumentData());
            boolean vehicleSubmitted = hasValue(driver.getVehicleDocumentStorageKey()) || hasValue(driver.getVehicleDocumentData());
            boolean insuranceSubmitted = hasValue(driver.getInsuranceDocumentStorageKey()) || hasValue(driver.getInsuranceDocumentData());
            boolean documentsComplete = profilePhotoSubmitted && aadhaarSubmitted && licenseSubmitted && vehicleSubmitted && insuranceSubmitted;
            return new AdminDriverResponse(
                    driver.getId(),
                    driver.getUser().getId(),
                    driver.getUser().getFullName(),
                    driver.getUser().getMobileNumber(),
                    driver.getUser().getEmail(),
                    driver.getGender(),
                    driver.getAge(),
                    aadhaarSubmitted ? "SUBMITTED" : "MISSING",
                    licenseSubmitted ? "SUBMITTED" : "MISSING",
                    driver.getVehicleType(),
                    driver.getVehicleRegistrationNumber(),
                    insuranceSubmitted ? "SUBMITTED" : "MISSING",
                    documentsComplete ? "SUBMITTED" : "DOCUMENTS_PENDING",
                    approvalStatus(driver),
                    driver.isAvailable() || driver.isOnline() ? "ACTIVE" : "INACTIVE",
                    driver.getVerificationStatus(),
                    driver.getVerificationRejectionReason(),
                    driver.getKycStatus(),
                    driver.getAdminApprovalStatus(),
                    driver.isAdminApproved(),
                    driver.isAvailable(),
                    driver.isOnline(),
                    driver.getAadhaarLast4(),
                    driver.getProfilePhotoStorageKey(),
                    driver.getAadhaarStorageKey(),
                    driver.getLicenseStorageKey(),
                    driver.getVehicleDocumentStorageKey(),
                    driver.getInsuranceDocumentStorageKey(),
                    driver.getProfilePhotoData(),
                    driver.getAadhaarDocumentData(),
                    driver.getLicenseDocumentData(),
                    driver.getVehicleDocumentData(),
                    driver.getInsuranceDocumentData(),
                    driver.getCreatedAt(),
                    driver.getUpdatedAt()
            );
        }

        private static String approvalStatus(DriverProfile driver) {
            if (driver.getAdminApprovalStatus() == AdminApprovalStatus.APPROVED || driver.isAdminApproved()) {
                return "APPROVED";
            }
            if (driver.getAdminApprovalStatus() == AdminApprovalStatus.REJECTED
                    || driver.getVerificationStatus() == DriverVerificationStatus.REJECTED) {
                return "REJECTED";
            }
            return "PENDING";
        }

        private static boolean hasValue(String value) {
            return value != null && !value.isBlank();
        }
    }

    @Schema(name = "PendingDriverVerificationResponse", description = "Admin-safe driver verification row for pending KYC/admin approval review.")
    public record PendingDriverVerificationResponse(
            @Schema(example = "3f6c7b7a-4d5b-4bd5-8c6a-2a7f8b7d9c10") UUID driverId,
            @Schema(example = "1a6c7b7a-4d5b-4bd5-8c6a-2a7f8b7d9c10") UUID userId,
            @Schema(example = "Priya Sharma") String fullName,
            @Schema(example = "9876543210") String mobileNumber,
            @Schema(example = "FEMALE") Gender gender,
            @Schema(example = "24") int age,
            @Schema(example = "SCOOTY") VehicleType vehicleType,
            @Schema(example = "DL01AB1234") String vehicleRegistrationNumber,
            @Schema(example = "PENDING") KycStatus kycStatus,
            @Schema(example = "PENDING") AdminApprovalStatus adminApprovalStatus,
            @Schema(example = "false") boolean adminApproved,
            @Schema(example = "PENDING_VERIFICATION") DriverVerificationStatus verificationStatus,
            String verificationRejectionReason,
            @Schema(example = "false") boolean available,
            @Schema(example = "false") boolean online,
            @Schema(example = "1234") String aadhaarLast4,
            @Schema(example = "profile-photos/driver-123.png") String profilePhotoStorageKey,
            String aadhaarStorageKey,
            String licenseStorageKey,
            String vehicleDocumentStorageKey,
            String insuranceDocumentStorageKey,
            String profilePhotoData,
            String aadhaarDocumentData,
            String licenseDocumentData,
            String vehicleDocumentData,
            String insuranceDocumentData
    ) {
        public static PendingDriverVerificationResponse from(DriverProfileRepository.PendingDriverVerificationRow row) {
            return new PendingDriverVerificationResponse(
                    row.getDriverId(),
                    row.getUserId(),
                    row.getFullName(),
                    row.getMobileNumber(),
                    parseEnum(Gender.class, row.getGender()),
                    row.getAge() == null ? 0 : row.getAge(),
                    parseEnum(VehicleType.class, row.getVehicleType()),
                    row.getVehicleRegistrationNumber(),
                    parseEnum(KycStatus.class, row.getKycStatus()),
                    parseEnum(AdminApprovalStatus.class, row.getAdminApprovalStatus()),
                    Boolean.TRUE.equals(row.getAdminApproved()),
                    parseEnum(DriverVerificationStatus.class, row.getVerificationStatus()),
                    row.getVerificationRejectionReason(),
                    Boolean.TRUE.equals(row.getAvailable()),
                    Boolean.TRUE.equals(row.getOnline()),
                    row.getAadhaarLast4(),
                    row.getProfilePhotoStorageKey(),
                    row.getAadhaarStorageKey(),
                    row.getLicenseStorageKey(),
                    row.getVehicleDocumentStorageKey(),
                    row.getInsuranceDocumentStorageKey(),
                    row.getProfilePhotoData(),
                    row.getAadhaarDocumentData(),
                    row.getLicenseDocumentData(),
                    row.getVehicleDocumentData(),
                    row.getInsuranceDocumentData()
            );
        }

        private static <T extends Enum<T>> T parseEnum(Class<T> type, String value) {
            if (value == null || value.isBlank()) {
                return null;
            }
            return Enum.valueOf(type, value);
        }
    }
}
