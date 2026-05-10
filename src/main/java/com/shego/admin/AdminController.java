package com.shego.admin;

import com.shego.common.AccountStatus;
import com.shego.common.AdminApprovalStatus;
import com.shego.common.ApiResponse;
import com.shego.common.KycStatus;
import com.shego.common.VerificationType;
import com.shego.driver.DriverDtos;
import com.shego.driver.DriverProfileRepository;
import com.shego.driver.DriverService;
import com.shego.rider.RiderDtos;
import com.shego.rider.RiderProfileRepository;
import com.shego.ride.Ride;
import com.shego.ride.RideService;
import com.shego.sos.SosService;
import com.shego.user.CurrentUserService;
import com.shego.user.UserDtos;
import com.shego.user.UserRepository;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/admin")
@PreAuthorize("hasAnyRole('ADMIN','SUPPORT')")
public class AdminController {
    private final UserRepository users;
    private final RideService rides;
    private final SosService sos;
    private final DriverService drivers;
    private final DriverProfileRepository driverProfiles;
    private final RiderProfileRepository riderProfiles;
    private final AdminActionLogRepository logs;
    private final CurrentUserService currentUserService;

    public AdminController(UserRepository users, RideService rides, SosService sos, DriverService drivers,
                           DriverProfileRepository driverProfiles, RiderProfileRepository riderProfiles,
                           AdminActionLogRepository logs, CurrentUserService currentUserService) {
        this.users = users;
        this.rides = rides;
        this.sos = sos;
        this.drivers = drivers;
        this.driverProfiles = driverProfiles;
        this.riderProfiles = riderProfiles;
        this.logs = logs;
        this.currentUserService = currentUserService;
    }

    @GetMapping("/dashboard")
    ApiResponse<Map<String, Object>> dashboard() {
        return ApiResponse.ok("Dashboard", Map.of(
                "users", users.count(),
                "activeRides", rides.active().size(),
                "activeSos", sos.active().size()
        ));
    }

    @GetMapping("/users")
    ApiResponse<java.util.List<UserDtos.UserResponse>> users() {
        return ApiResponse.ok("Users", this.users.findAll().stream().map(UserDtos.UserResponse::from).toList());
    }

    @PostMapping("/users/{id}/suspend")
    ApiResponse<Void> suspend(@PathVariable UUID id) {
        var user = users.findById(id).orElseThrow();
        user.setAccountStatus(AccountStatus.SUSPENDED);
        users.save(user);
        log("SUSPEND_USER", "User", id.toString(), null);
        return ApiResponse.ok("User suspended", null);
    }

    @PostMapping("/users/{id}/block")
    ApiResponse<Void> block(@PathVariable UUID id) {
        var user = users.findById(id).orElseThrow();
        user.setAccountStatus(AccountStatus.BLOCKED);
        users.save(user);
        log("BLOCK_USER", "User", id.toString(), null);
        return ApiResponse.ok("User blocked", null);
    }

    @PostMapping("/drivers/{id}/approve")
    ApiResponse<DriverDtos.DriverResponse> approveDriver(@PathVariable UUID id) {
        log("APPROVE_DRIVER", "DriverProfile", id.toString(), null);
        return ApiResponse.ok("Driver approved", drivers.response(drivers.approve(id)));
    }

    @GetMapping("/rides/active")
    ApiResponse<java.util.List<Ride>> activeRides() {
        return ApiResponse.ok("Active rides", rides.active());
    }

    @GetMapping("/reports")
    ApiResponse<Map<String, Object>> reports() {
        return ApiResponse.ok("Reports", Map.of(
                "message", "Exportable operational, safety, payment, and KYC reports are modeled here for Phase 2."
        ));
    }

    @GetMapping("/minor-riders")
    ApiResponse<java.util.List<RiderDtos.RiderProfileResponse>> minorRiders() {
        return ApiResponse.ok("Minor riders", riderProfiles.findByRiderAgeLessThan(18).stream()
                .map(RiderDtos.RiderProfileResponse::from).toList());
    }

    @GetMapping("/pending-guardian-verifications")
    ApiResponse<java.util.List<RiderDtos.RiderProfileResponse>> pendingGuardianVerifications() {
        return ApiResponse.ok("Pending guardian verifications",
                riderProfiles.findByVerificationTypeAndKycStatus(VerificationType.GUARDIAN_AADHAAR, KycStatus.PENDING)
                        .stream().map(RiderDtos.RiderProfileResponse::from).toList());
    }

    @GetMapping("/pending-driver-kyc")
    ApiResponse<java.util.List<DriverDtos.DriverProfileResponse>> pendingDriverKyc() {
        return ApiResponse.ok("Pending driver KYC", driverProfiles.findByKycStatus(KycStatus.PENDING)
                .stream().map(DriverDtos.DriverProfileResponse::from).toList());
    }

    @PostMapping("/approve-rider-verification")
    ApiResponse<RiderDtos.RiderProfileResponse> approveRiderVerification(@org.springframework.web.bind.annotation.RequestParam UUID riderId) {
        var rider = riderProfiles.findById(riderId).orElseThrow();
        rider.setKycStatus(KycStatus.APPROVED);
        rider.getUser().setAccountStatus(AccountStatus.ACTIVE);
        users.save(rider.getUser());
        log("APPROVE_RIDER_VERIFICATION", "RiderProfile", riderId.toString(), rider.getVerificationType() == null ? null : rider.getVerificationType().name());
        return ApiResponse.ok("Rider verification approved", RiderDtos.RiderProfileResponse.from(riderProfiles.save(rider)));
    }

    @PostMapping("/approve-driver-verification")
    ApiResponse<DriverDtos.DriverProfileResponse> approveDriverVerification(@org.springframework.web.bind.annotation.RequestParam UUID driverId) {
        var driver = driverProfiles.findById(driverId).orElseThrow();
        driver.setKycStatus(KycStatus.APPROVED);
        driver.setAdminApprovalStatus(AdminApprovalStatus.APPROVED);
        driver.setAdminApproved(true);
        driver.getUser().setAccountStatus(AccountStatus.ACTIVE);
        users.save(driver.getUser());
        log("APPROVE_DRIVER_VERIFICATION", "DriverProfile", driverId.toString(), null);
        return ApiResponse.ok("Driver verification approved", DriverDtos.DriverProfileResponse.from(driverProfiles.save(driver)));
    }

    private void log(String action, String targetType, String targetId, String notes) {
        AdminActionLog log = new AdminActionLog();
        log.setAdmin(currentUserService.current());
        log.setAction(action);
        log.setTargetType(targetType);
        log.setTargetId(targetId);
        log.setNotes(notes);
        logs.save(log);
    }
}
