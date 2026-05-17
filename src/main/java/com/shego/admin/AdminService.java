package com.shego.admin;

import com.shego.common.AccountStatus;
import com.shego.common.AdminApprovalStatus;
import com.shego.common.KycStatus;
import com.shego.common.DriverVerificationStatus;
import com.shego.common.NotificationType;
import com.shego.common.Role;
import com.shego.common.VerificationType;
import com.shego.driver.DriverProfileRepository;
import com.shego.exception.BusinessException;
import com.shego.notification.NotificationService;
import com.shego.rider.RiderProfileRepository;
import com.shego.driver.DriverDtos;
import com.shego.driver.DriverProfile;
import com.shego.user.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
public class AdminService {
    private static final Logger log = LoggerFactory.getLogger(AdminService.class);

    private final DriverProfileRepository driverProfiles;
    private final RiderProfileRepository riderProfiles;
    private final UserRepository users;
    private final NotificationService notifications;

    public AdminService(DriverProfileRepository driverProfiles, RiderProfileRepository riderProfiles, UserRepository users,
                        NotificationService notifications) {
        this.driverProfiles = driverProfiles;
        this.riderProfiles = riderProfiles;
        this.users = users;
        this.notifications = notifications;
    }

    public List<AdminDtos.PendingDriverVerificationResponse> pendingDriverVerifications() {
        log.debug("AdminService pending driver verification flow started");
        var pendingRows = driverProfiles.findPendingVerificationRows();
        log.debug("Pending driver repository result count: {}", pendingRows.size());
        log.debug("Pending driver DTO mapping started");
        var response = pendingRows.stream()
                .map(AdminDtos.PendingDriverVerificationResponse::from)
                .toList();
        log.debug("Pending driver DTO mapping completed: {}", response.size());
        return response;
    }

    @Transactional
    public AdminDtos.RiderApprovalResponse approveRiderVerification(UUID riderId) {
        log.debug("AdminService approve rider entry: riderId={}", riderId);
        log.debug("Rider approval row lookup started: riderId={}", riderId);
        var row = riderProfiles.findApprovalRow(riderId)
                .orElseThrow(() -> new BusinessException("Rider not found", HttpStatus.NOT_FOUND));
        log.debug("Rider approval row lookup completed: riderId={}, userId={}, kycStatus={}, accountStatus={}, verificationType={}",
                row.getId(), row.getUserId(), row.getKycStatus(), row.getAccountStatus(), row.getVerificationType());

        if (!KycStatus.APPROVED.name().equals(row.getKycStatus())) {
            log.debug("Updating rider_profile.kyc_status to APPROVED: riderId={}", riderId);
            riderProfiles.approveRiderKyc(riderId);
        } else {
            log.debug("Rider already has APPROVED KYC status: riderId={}", riderId);
        }
        if (!AccountStatus.ACTIVE.name().equals(row.getAccountStatus())) {
            log.debug("Updating users.account_status to ACTIVE: userId={}", row.getUserId());
            users.activateUser(row.getUserId());
        } else {
            log.debug("Linked user already ACTIVE: userId={}", row.getUserId());
        }
        var verificationType = parseEnum(VerificationType.class, row.getVerificationType());
        log.debug("Rider approval response return: riderId={}, kycStatus=APPROVED, accountStatus=ACTIVE, verificationType={}",
                riderId, verificationType);
        return new AdminDtos.RiderApprovalResponse(riderId, KycStatus.APPROVED, AccountStatus.ACTIVE, verificationType);
    }

    private static <T extends Enum<T>> T parseEnum(Class<T> type, String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return Enum.valueOf(type, value);
    }

    @Transactional
    public DriverDtos.DriverProfileResponse approveDriverVerification(UUID driverId) {
        var saved = approveDriverProfile(driverId);
        return DriverDtos.DriverProfileResponse.from(saved);
    }

    @Transactional
    public AdminDtos.DriverApprovalResponse approveDriverVerificationSummary(UUID driverId) {
        var saved = approveDriverProfile(driverId);
        return new AdminDtos.DriverApprovalResponse(
                saved.getId(),
                saved.getKycStatus(),
                saved.getAdminApprovalStatus(),
                saved.isAdminApproved()
        );
    }

    private DriverProfile approveDriverProfile(UUID driverId) {
        log.debug("AdminService approve driver entry: driverId={}", driverId);
        var driver = driverProfiles.findByIdWithUser(driverId)
                .orElseThrow(() -> new BusinessException("Driver not found", HttpStatus.NOT_FOUND));
        log.debug("Driver lookup completed: driverId={}, userId={}, kycStatus={}, adminApprovalStatus={}, adminApproved={}",
                driver.getId(), driver.getUser().getId(), driver.getKycStatus(), driver.getAdminApprovalStatus(), driver.isAdminApproved());
        if (driver.getVerificationStatus() != DriverVerificationStatus.PENDING_VERIFICATION) {
            throw new BusinessException("Driver documents must be submitted before approval");
        }
        driver.setKycStatus(KycStatus.APPROVED);
        driver.setAdminApprovalStatus(AdminApprovalStatus.APPROVED);
        driver.setAdminApproved(true);
        driver.setVerificationStatus(DriverVerificationStatus.APPROVED);
        driver.setVerificationRejectionReason(null);
        driver.setAvailable(false);
        driver.setOnline(false);
        driver.getUser().setAccountStatus(AccountStatus.ACTIVE);
        users.save(driver.getUser());
        var saved = driverProfiles.save(driver);
        notifications.create(saved.getUser(), Role.DRIVER, NotificationType.APPROVAL,
                "Driver verification approved",
                "Your documents were approved by Admin. You can now go active for rides.",
                "DriverProfile", saved.getId().toString(), "driver-profile",
                "driver-approved:" + saved.getId());
        log.debug("Driver approval response return: driverId={}, kycStatus={}, adminApprovalStatus={}, adminApproved={}",
                saved.getId(), saved.getKycStatus(), saved.getAdminApprovalStatus(), saved.isAdminApproved());
        return saved;
    }

    @Transactional
    public DriverDtos.DriverProfileResponse rejectDriverVerification(UUID driverId, String reason) {
        log.debug("AdminService reject driver entry: driverId={}, reasonPresent={}", driverId, reason != null && !reason.isBlank());
        var driver = driverProfiles.findByIdWithUser(driverId)
                .orElseThrow(() -> new BusinessException("Driver not found", HttpStatus.NOT_FOUND));
        driver.setKycStatus(KycStatus.REJECTED);
        driver.setAdminApprovalStatus(AdminApprovalStatus.REJECTED);
        driver.setAdminApproved(false);
        driver.setVerificationStatus(DriverVerificationStatus.REJECTED);
        driver.setVerificationRejectionReason(reason == null || reason.isBlank() ? "Admin rejected driver verification." : reason);
        driver.setAvailable(false);
        driver.setOnline(false);
        var saved = driverProfiles.save(driver);
        notifications.create(saved.getUser(), Role.DRIVER, NotificationType.REJECTION,
                "Driver verification rejected",
                saved.getVerificationRejectionReason(),
                "DriverProfile", saved.getId().toString(), "driver-documents",
                "driver-rejected:" + saved.getId());
        log.debug("Driver rejection response return: driverId={}, kycStatus={}, adminApprovalStatus={}",
                saved.getId(), saved.getKycStatus(), saved.getAdminApprovalStatus());
        return DriverDtos.DriverProfileResponse.from(saved);
    }

    @Transactional
    public DriverDtos.DriverProfileResponse requestDriverResubmission(UUID driverId, String reason) {
        var driver = driverProfiles.findByIdWithUser(driverId)
                .orElseThrow(() -> new BusinessException("Driver not found", HttpStatus.NOT_FOUND));
        driver.setVerificationStatus(DriverVerificationStatus.RESUBMISSION_REQUIRED);
        driver.setVerificationRejectionReason(reason == null || reason.isBlank()
                ? "Admin requested updated documents." : reason);
        driver.setKycStatus(KycStatus.PENDING);
        driver.setAdminApprovalStatus(AdminApprovalStatus.PENDING);
        driver.setAdminApproved(false);
        driver.setAvailable(false);
        driver.setOnline(false);
        var saved = driverProfiles.save(driver);
        notifications.create(saved.getUser(), Role.DRIVER, NotificationType.ACTION_REQUIRED,
                "Document re-submission required",
                saved.getVerificationRejectionReason(),
                "DriverProfile", saved.getId().toString(), "driver-documents",
                "driver-resubmission-required:" + saved.getId());
        return DriverDtos.DriverProfileResponse.from(saved);
    }
}
