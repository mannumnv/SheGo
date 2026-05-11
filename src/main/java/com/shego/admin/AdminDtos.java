package com.shego.admin;

import com.shego.common.AdminApprovalStatus;
import com.shego.common.Gender;
import com.shego.common.KycStatus;
import com.shego.common.VehicleType;
import com.shego.driver.DriverProfileRepository;
import io.swagger.v3.oas.annotations.media.Schema;

import java.util.UUID;

public class AdminDtos {
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
            @Schema(example = "false") boolean available,
            @Schema(example = "false") boolean online,
            @Schema(example = "1234") String aadhaarLast4,
            @Schema(example = "profile-photos/driver-123.png") String profilePhotoStorageKey
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
                    Boolean.TRUE.equals(row.getAvailable()),
                    Boolean.TRUE.equals(row.getOnline()),
                    row.getAadhaarLast4(),
                    row.getProfilePhotoStorageKey()
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
