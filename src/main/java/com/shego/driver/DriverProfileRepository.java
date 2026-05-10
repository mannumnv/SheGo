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
}
