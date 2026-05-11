package com.shego.driver;

import com.shego.user.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface DriverProfileRepository extends JpaRepository<DriverProfile, UUID> {
    Optional<DriverProfile> findByUser(User user);
    List<DriverProfile> findByKycStatus(com.shego.common.KycStatus status);
    List<DriverProfile> findByAdminApprovalStatus(com.shego.common.AdminApprovalStatus status);

    @Query("select d from DriverProfile d where d.online = true and d.available = true and d.adminApproved = true and d.kycStatus = com.shego.common.KycStatus.APPROVED")
    List<DriverProfile> findAvailableApprovedDrivers();

    @Query("""
            select distinct d
            from DriverProfile d
            join fetch d.user u
            where d.kycStatus = com.shego.common.KycStatus.PENDING
               or d.adminApprovalStatus = com.shego.common.AdminApprovalStatus.PENDING
               or d.adminApproved = false
            """)
    List<DriverProfile> findPendingVerificationDrivers();

    @Query(value = """
            select distinct on (dp.id)
                dp.id as "driverId",
                u.id as "userId",
                u.full_name as "fullName",
                u.mobile_number as "mobileNumber",
                dp.gender as "gender",
                dp.age as "age",
                coalesce(v.vehicle_type, dp.vehicle_type) as "vehicleType",
                coalesce(v.registration_number, dp.vehicle_registration_number) as "vehicleRegistrationNumber",
                dp.kyc_status as "kycStatus",
                dp.admin_approval_status as "adminApprovalStatus",
                dp.admin_approved as "adminApproved",
                dp.available as "available",
                dp.online as "online",
                dp.aadhaar_last4 as "aadhaarLast4",
                dp.profile_photo_storage_key as "profilePhotoStorageKey"
            from driver_profile dp
            join users u on dp.user_id = u.id
            left join vehicle v on v.driver_id = dp.id and v.active = true
            where dp.kyc_status = 'PENDING'
               or dp.admin_approval_status = 'PENDING'
               or dp.admin_approved = false
            order by dp.id, v.created_at desc
            """, nativeQuery = true)
    List<PendingDriverVerificationRow> findPendingVerificationRows();

    interface PendingDriverVerificationRow {
        UUID getDriverId();
        UUID getUserId();
        String getFullName();
        String getMobileNumber();
        String getGender();
        Integer getAge();
        String getVehicleType();
        String getVehicleRegistrationNumber();
        String getKycStatus();
        String getAdminApprovalStatus();
        Boolean getAdminApproved();
        Boolean getAvailable();
        Boolean getOnline();
        String getAadhaarLast4();
        String getProfilePhotoStorageKey();
    }
}
