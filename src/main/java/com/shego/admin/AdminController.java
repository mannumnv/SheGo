package com.shego.admin;

import com.shego.common.AccountStatus;
import com.shego.common.ApiResponse;
import com.shego.common.KycStatus;
import com.shego.common.VerificationType;
import com.shego.exception.BusinessException;
import com.shego.driver.DriverDtos;
import com.shego.driver.DriverProfileRepository;
import com.shego.rider.RiderDtos;
import com.shego.rider.RiderProfileRepository;
import com.shego.ride.RideDtos;
import com.shego.ride.RideService;
import com.shego.sos.SosService;
import com.shego.user.CurrentUserService;
import com.shego.user.UserDtos;
import com.shego.user.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/admin")
@PreAuthorize("hasRole('ADMIN')")
public class AdminController {
    private static final Logger logger = LoggerFactory.getLogger(AdminController.class);

    private final UserRepository users;
    private final RideService rides;
    private final SosService sos;
    private final DriverProfileRepository driverProfiles;
    private final RiderProfileRepository riderProfiles;
    private final AdminActionLogRepository logs;
    private final CurrentUserService currentUserService;
    private final AdminService adminService;

    public AdminController(UserRepository users, RideService rides, SosService sos,
                           DriverProfileRepository driverProfiles, RiderProfileRepository riderProfiles,
                           AdminActionLogRepository logs, CurrentUserService currentUserService, AdminService adminService) {
        this.users = users;
        this.rides = rides;
        this.sos = sos;
        this.driverProfiles = driverProfiles;
        this.riderProfiles = riderProfiles;
        this.logs = logs;
        this.currentUserService = currentUserService;
        this.adminService = adminService;
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
        var user = users.findById(id)
                .orElseThrow(() -> new BusinessException("User not found", HttpStatus.NOT_FOUND));
        user.setAccountStatus(AccountStatus.SUSPENDED);
        users.save(user);
        log("SUSPEND_USER", "User", id.toString(), null);
        return ApiResponse.ok("User suspended", null);
    }

    @PostMapping("/users/{id}/block")
    ApiResponse<Void> block(@PathVariable UUID id) {
        var user = users.findById(id)
                .orElseThrow(() -> new BusinessException("User not found", HttpStatus.NOT_FOUND));
        user.setAccountStatus(AccountStatus.BLOCKED);
        users.save(user);
        log("BLOCK_USER", "User", id.toString(), null);
        return ApiResponse.ok("User blocked", null);
    }

    @PostMapping("/drivers/{id}/approve")
    @io.swagger.v3.oas.annotations.Operation(
            summary = "Approve driver by driverId",
            description = "Approves a driver_profile using driverId. This endpoint is separate from KYC document approval and is safe when local/dev KYC document rows are missing."
    )
    @io.swagger.v3.oas.annotations.responses.ApiResponse(
            responseCode = "200",
            description = "Driver approved successfully",
            content = @io.swagger.v3.oas.annotations.media.Content(
                    mediaType = "application/json",
                    schema = @io.swagger.v3.oas.annotations.media.Schema(implementation = AdminDtos.DriverApprovalResponse.class),
                    examples = @io.swagger.v3.oas.annotations.media.ExampleObject(value = """
                            {
                              "success": true,
                              "message": "Driver approved successfully",
                              "data": {
                                "driverId": "3f6c7b7a-4d5b-4bd5-8c6a-2a7f8b7d9c10",
                                "kycStatus": "APPROVED",
                                "adminApprovalStatus": "APPROVED",
                                "adminApproved": true
                              }
                            }
                            """)
            )
    )
    ApiResponse<AdminDtos.DriverApprovalResponse> approveDriver(@PathVariable UUID id) {
        logger.debug("AdminController entry: POST /api/admin/drivers/{id}/approve driverId={}", id);
        var response = adminService.approveDriverVerificationSummary(id);
        log("APPROVE_DRIVER", "DriverProfile", id.toString(), null);
        logger.debug("AdminController return: driver approved driverId={}, kycStatus={}, adminApprovalStatus={}, adminApproved={}",
                response.driverId(), response.kycStatus(), response.adminApprovalStatus(), response.adminApproved());
        return ApiResponse.ok("Driver approved successfully", response);
    }

    @GetMapping("/rides/active")
    ApiResponse<java.util.List<RideDtos.RideResponse>> activeRides() {
        return ApiResponse.ok("Active rides", rides.active().stream().map(RideDtos.RideResponse::from).toList());
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
    @io.swagger.v3.oas.annotations.Operation(
            summary = "List pending driver verifications",
            description = "Returns drivers whose KYC is pending, admin approval is pending, or adminApproved is false. Response joins user data and includes vehicle details without exposing Aadhaar or KYC documents."
    )
    @io.swagger.v3.oas.annotations.responses.ApiResponse(
            responseCode = "200",
            description = "Pending driver verification rows",
            content = @io.swagger.v3.oas.annotations.media.Content(
                    mediaType = "application/json",
                    schema = @io.swagger.v3.oas.annotations.media.Schema(implementation = AdminDtos.PendingDriverVerificationResponse.class),
                    examples = @io.swagger.v3.oas.annotations.media.ExampleObject(value = """
                            {
                              "success": true,
                              "message": "Pending driver verification",
                              "data": [
                                {
                                  "driverId": "3f6c7b7a-4d5b-4bd5-8c6a-2a7f8b7d9c10",
                                  "userId": "1a6c7b7a-4d5b-4bd5-8c6a-2a7f8b7d9c10",
                                  "fullName": "Priya Sharma",
                                  "mobileNumber": "9876543210",
                                  "gender": "FEMALE",
                                  "age": 24,
                                  "vehicleType": "SCOOTY",
                                  "vehicleRegistrationNumber": "DL01AB1234",
                                  "kycStatus": "PENDING",
                                  "adminApprovalStatus": "PENDING",
                                  "adminApproved": false,
                                  "available": false,
                                  "online": false,
                                  "aadhaarLast4": "1234",
                                  "profilePhotoStorageKey": null
                                }
                              ]
                            }
                            """)
            )
    )
    ApiResponse<java.util.List<AdminDtos.PendingDriverVerificationResponse>> pendingDriverKyc() {
        logger.debug("AdminController entry: GET /api/admin/pending-driver-kyc");
        return ApiResponse.ok("Pending driver verification", adminService.pendingDriverVerifications());
    }

    @PostMapping("/approve-rider-verification")
    @io.swagger.v3.oas.annotations.Operation(summary = "Approve rider verification", description = "Approves rider_profile by riderId and activates the linked user. Safe if guardian/KYC document rows are missing in local/dev.")
    @io.swagger.v3.oas.annotations.responses.ApiResponse(
            responseCode = "200",
            description = "Rider verification approved",
            content = @io.swagger.v3.oas.annotations.media.Content(
                    mediaType = "application/json",
                    examples = @io.swagger.v3.oas.annotations.media.ExampleObject(value = """
                            {
                              "success": true,
                              "message": "Rider verification approved",
                              "data": {
                                "id": "rider-profile-uuid",
                                "kycStatus": "APPROVED",
                                "accountStatus": "ACTIVE"
                              }
                            }
                            """)
            )
    )
    ApiResponse<AdminDtos.RiderApprovalResponse> approveRiderVerification(@org.springframework.web.bind.annotation.RequestParam UUID riderId) {
        logger.debug("AdminController entry: POST /api/admin/approve-rider-verification riderId={}", riderId);
        var response = adminService.approveRiderVerification(riderId);
        log("APPROVE_RIDER_VERIFICATION", "RiderProfile", riderId.toString(), response.verificationType() == null ? null : response.verificationType().name());
        logger.debug("AdminController return: rider approval riderId={}, kycStatus={}", riderId, response.kycStatus());
        return ApiResponse.ok("Rider verification approved", response);
    }

    @PostMapping("/approve-driver-verification")
    @io.swagger.v3.oas.annotations.Operation(summary = "Approve driver verification", description = "Approves driver_profile by driverId. This is separate from KYC document approval.")
    ApiResponse<DriverDtos.DriverProfileResponse> approveDriverVerification(@RequestParam UUID driverId) {
        logger.debug("AdminController entry: POST /api/admin/approve-driver-verification driverId={}", driverId);
        var response = adminService.approveDriverVerification(driverId);
        log("APPROVE_DRIVER_VERIFICATION", "DriverProfile", driverId.toString(), null);
        logger.debug("AdminController return: driver approval driverId={}, kycStatus={}, adminApprovalStatus={}",
                driverId, response.kycStatus(), response.adminApprovalStatus());
        return ApiResponse.ok("Driver verification approved", response);
    }

    @PostMapping("/reject-driver-verification")
    ApiResponse<DriverDtos.DriverProfileResponse> rejectDriverVerification(@RequestParam UUID driverId,
                                                                           @RequestParam(required = false) String reason) {
        logger.debug("AdminController entry: POST /api/admin/reject-driver-verification driverId={}", driverId);
        var response = adminService.rejectDriverVerification(driverId, reason);
        log("REJECT_DRIVER_VERIFICATION", "DriverProfile", driverId.toString(), reason);
        return ApiResponse.ok("Driver verification rejected", response);
    }

    @PostMapping("/request-driver-resubmission")
    ApiResponse<DriverDtos.DriverProfileResponse> requestDriverResubmission(@RequestParam UUID driverId,
                                                                            @RequestParam(required = false) String reason) {
        var response = adminService.requestDriverResubmission(driverId, reason);
        log("REQUEST_DRIVER_RESUBMISSION", "DriverProfile", driverId.toString(), reason);
        return ApiResponse.ok("Driver document re-submission requested", response);
    }

    private void log(String action, String targetType, String targetId, String notes) {
        AdminActionLog log = new AdminActionLog();
        var currentAdmin = currentUserService.current();
        log.setAdmin(users.getReferenceById(currentAdmin.getId()));
        log.setAction(action);
        log.setTargetType(targetType);
        log.setTargetId(targetId);
        log.setNotes(notes);
        logs.save(log);
    }
}
