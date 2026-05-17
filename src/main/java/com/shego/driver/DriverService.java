package com.shego.driver;

import com.shego.auth.AuthDtos;
import com.shego.common.AdminApprovalStatus;
import com.shego.common.AccountStatus;
import com.shego.common.DriverVerificationStatus;
import com.shego.common.EligibilityValidationService;
import com.shego.common.KycStatus;
import com.shego.common.NotificationType;
import com.shego.common.Role;
import com.shego.common.VehicleType;
import com.shego.config.JwtService;
import com.shego.exception.BusinessException;
import com.shego.notification.NotificationService;
import com.shego.payment.DriverEarningRepository;
import com.shego.user.User;
import com.shego.user.UserRepository;
import com.shego.vehicle.Vehicle;
import com.shego.vehicle.VehicleRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Set;
import java.util.UUID;

@Service
public class DriverService {
    private static final Logger log = LoggerFactory.getLogger(DriverService.class);

    private final DriverProfileRepository drivers;
    private final VehicleRepository vehicles;
    private final UserRepository users;
    private final DriverEarningRepository earnings;
    private final StringRedisTemplate redis;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;
    private final JwtService jwtService;
    private final EligibilityValidationService eligibility;
    private final NotificationService notifications;

    public DriverService(DriverProfileRepository drivers, VehicleRepository vehicles, UserRepository users,
                         DriverEarningRepository earnings, StringRedisTemplate redis, PasswordEncoder passwordEncoder,
                         AuthenticationManager authenticationManager, JwtService jwtService,
                         EligibilityValidationService eligibility, NotificationService notifications) {
        this.drivers = drivers;
        this.vehicles = vehicles;
        this.users = users;
        this.earnings = earnings;
        this.redis = redis;
        this.passwordEncoder = passwordEncoder;
        this.authenticationManager = authenticationManager;
        this.jwtService = jwtService;
        this.eligibility = eligibility;
        this.notifications = notifications;
    }

    @Transactional
    public AuthDtos.AuthResponse signup(DriverDtos.SignupRequest request) {
        if (users.existsByMobileNumber(request.mobileNumber())) {
            throw new BusinessException("Mobile number already registered");
        }
        int age = eligibility.validateDriver(request.gender(), request.dateOfBirth());
        User user = new User();
        user.setFullName(request.fullName());
        user.setMobileNumber(request.mobileNumber());
        user.setRoles(Set.of(Role.DRIVER));
        user.setPasswordHash(passwordEncoder.encode(request.password() == null ? request.mobileNumber() : request.password()));
        user.setAccountStatus(AccountStatus.PENDING);
        user.setFemaleVerified(true);
        User savedUser = users.save(user);

        DriverProfile driver = new DriverProfile();
        driver.setUser(savedUser);
        driver.setLicenseNumber(request.drivingLicenseNumber());
        driver.setDrivingLicenseNumber(request.drivingLicenseNumber());
        driver.setGender(request.gender());
        driver.setDateOfBirth(request.dateOfBirth());
        driver.setAge(age);
        driver.setAddress(request.address());
        driver.setAadhaarEncrypted(request.aadhaarNumber());
        driver.setAadhaarLast4(last4(request.aadhaarNumber()));
        driver.setVehicleType(request.vehicleType());
        driver.setVehicleRegistrationNumber(request.vehicleRegistrationNumber());
        driver.setInsuranceDetails(request.insuranceDetails());
        driver.setProfilePhotoStorageKey(request.profilePhotoStorageKey());
        driver.setSelfieStorageKey(request.selfieStorageKey());
        driver.setAadhaarStorageKey(request.aadhaarStorageKey());
        driver.setLicenseStorageKey(request.licenseStorageKey());
        driver.setVehicleDocumentStorageKey(request.vehicleDocumentStorageKey());
        driver.setInsuranceDocumentStorageKey(request.insuranceDocumentStorageKey());
        driver.setVerificationStatus(documentsComplete(driver) ? DriverVerificationStatus.PENDING_VERIFICATION : DriverVerificationStatus.INCOMPLETE);
        DriverProfile savedDriver = drivers.save(driver);

        Vehicle vehicle = new Vehicle();
        vehicle.setDriver(savedDriver);
        vehicle.setVehicleType(request.vehicleType());
        vehicle.setRegistrationNumber(request.vehicleRegistrationNumber());
        vehicle.setInsurancePolicyNumber(request.insuranceDetails());
        vehicle.setActive(true);
        vehicles.save(vehicle);
        log.debug("Driver signup succeeded: driverId={}, userId={}, mobile={}",
                savedDriver.getId(), savedUser.getId(), savedUser.getMobileNumber());
        notifications.create(savedUser, Role.DRIVER, NotificationType.ACTION_REQUIRED,
                "Upload required KYC documents",
                "Please submit profile photo, Aadhaar, license, vehicle, and insurance documents before going active.",
                "DriverProfile", savedDriver.getId().toString(), "driver-documents",
                "driver-signup-docs:" + savedDriver.getId());
        notifications.createForRole(Role.ADMIN, NotificationType.ACTION_REQUIRED,
                "New driver signup",
                savedUser.getFullName() + " created a driver account. Documents are not submitted yet.",
                "DriverProfile", savedDriver.getId().toString(), "admin-driver-verification",
                "admin-driver-signup:" + savedDriver.getId());
        return tokens(savedUser);
    }

    public AuthDtos.AuthResponse login(DriverDtos.LoginRequest request) {
        authenticationManager.authenticate(new UsernamePasswordAuthenticationToken(request.mobileNumber(), request.password()));
        User user = users.findByMobileNumber(request.mobileNumber())
                .orElseThrow(() -> new BusinessException("Invalid credentials"));
        if (!user.getRoles().contains(Role.DRIVER)) {
            throw new BusinessException("Driver account not found");
        }
        return tokens(user);
    }

    public DriverProfile uploadKyc(User user, DriverDtos.UploadKycRequest request) {
        DriverProfile driver = driverFor(user);
        ensureDocumentSubmissionAllowed(driver);
        driver.setAadhaarEncrypted(request.aadhaarNumber());
        driver.setAadhaarLast4(last4(request.aadhaarNumber()));
        driver.setProfilePhotoStorageKey(request.profilePhotoStorageKey());
        driver.setSelfieStorageKey(request.selfieStorageKey());
        driver.setAadhaarStorageKey(request.aadhaarStorageKey());
        driver.setLicenseStorageKey(request.licenseStorageKey());
        driver.setVehicleDocumentStorageKey(request.vehicleDocumentStorageKey());
        driver.setInsuranceDocumentStorageKey(request.insuranceDocumentStorageKey());
        driver.setProfilePhotoData(request.profilePhotoData());
        driver.setAadhaarDocumentData(request.aadhaarDocumentData());
        driver.setLicenseDocumentData(request.licenseDocumentData());
        driver.setVehicleDocumentData(request.vehicleDocumentData());
        driver.setInsuranceDocumentData(request.insuranceDocumentData());
        if (!documentsComplete(driver)) {
            driver.setVerificationStatus(DriverVerificationStatus.INCOMPLETE);
            driver.setKycStatus(KycStatus.PENDING);
            driver.setAdminApprovalStatus(AdminApprovalStatus.PENDING);
            driver.setAdminApproved(false);
            driver.setAvailable(false);
            driver.setOnline(false);
            return drivers.save(driver);
        }
        driver.setKycStatus(KycStatus.PENDING);
        driver.setAdminApprovalStatus(AdminApprovalStatus.PENDING);
        driver.setAdminApproved(false);
        driver.setAvailable(false);
        driver.setOnline(false);
        boolean resubmission = driver.getVerificationStatus() == DriverVerificationStatus.REJECTED;
        driver.setVerificationStatus(DriverVerificationStatus.PENDING_VERIFICATION);
        driver.setVerificationRejectionReason(null);
        DriverProfile saved = drivers.save(driver);
        notifications.create(user, Role.DRIVER, NotificationType.INFO,
                "Documents submitted",
                "Your documents have been submitted and are pending admin verification.",
                "DriverProfile", saved.getId().toString(), "driver-documents",
                "driver-docs-submitted:" + saved.getId());
        notifications.createForRole(Role.ADMIN, NotificationType.ACTION_REQUIRED,
                resubmission ? "Driver re-submitted documents" : "Driver verification request received",
                user.getFullName() + " submitted driver verification documents for review.",
                "DriverProfile", saved.getId().toString(), "admin-driver-verification",
                (resubmission ? "admin-driver-resubmitted:" : "admin-driver-docs:") + saved.getId());
        return saved;
    }

    public DriverProfile submitDocuments(User user, DriverDtos.UploadKycRequest request) {
        DriverProfile driver = driverFor(user);
        ensureDocumentSubmissionAllowed(driver);
        boolean resubmission = driver.getVerificationStatus() == DriverVerificationStatus.REJECTED
                || driver.getVerificationStatus() == DriverVerificationStatus.RESUBMISSION_REQUIRED;
        applyIfPresent(request.profilePhotoStorageKey(), driver::setProfilePhotoStorageKey);
        applyIfPresent(request.selfieStorageKey(), driver::setSelfieStorageKey);
        applyIfPresent(request.aadhaarStorageKey(), driver::setAadhaarStorageKey);
        applyIfPresent(request.licenseStorageKey(), driver::setLicenseStorageKey);
        applyIfPresent(request.vehicleDocumentStorageKey(), driver::setVehicleDocumentStorageKey);
        applyIfPresent(request.insuranceDocumentStorageKey(), driver::setInsuranceDocumentStorageKey);
        applyIfPresent(request.profilePhotoData(), driver::setProfilePhotoData);
        applyIfPresent(request.aadhaarDocumentData(), driver::setAadhaarDocumentData);
        applyIfPresent(request.licenseDocumentData(), driver::setLicenseDocumentData);
        applyIfPresent(request.vehicleDocumentData(), driver::setVehicleDocumentData);
        applyIfPresent(request.insuranceDocumentData(), driver::setInsuranceDocumentData);
        if (request.aadhaarNumber() != null && !request.aadhaarNumber().isBlank()) {
            driver.setAadhaarEncrypted(request.aadhaarNumber());
            driver.setAadhaarLast4(last4(request.aadhaarNumber()));
        }
        if (!documentsComplete(driver)) {
            driver.setVerificationStatus(DriverVerificationStatus.INCOMPLETE);
            driver.setAvailable(false);
            driver.setOnline(false);
            throw new BusinessException("All required driver documents must be submitted before admin verification");
        }
        driver.setKycStatus(KycStatus.PENDING);
        driver.setAdminApprovalStatus(AdminApprovalStatus.PENDING);
        driver.setAdminApproved(false);
        driver.setAvailable(false);
        driver.setOnline(false);
        driver.setVerificationStatus(DriverVerificationStatus.PENDING_VERIFICATION);
        driver.setVerificationRejectionReason(null);
        DriverProfile saved = drivers.save(driver);
        notifications.create(user, Role.DRIVER, NotificationType.INFO,
                "Documents submitted",
                "Your documents have been submitted and are pending admin verification.",
                "DriverProfile", saved.getId().toString(), "driver-documents",
                "driver-docs-submitted:" + saved.getId());
        notifications.createForRole(Role.ADMIN, NotificationType.ACTION_REQUIRED,
                resubmission ? "Driver re-submitted documents" : "Driver verification request received",
                user.getFullName() + " submitted driver verification documents for review.",
                "DriverProfile", saved.getId().toString(), "admin-driver-verification",
                (resubmission ? "admin-driver-resubmitted:" : "admin-driver-docs:") + saved.getId());
        return saved;
    }

    @Transactional
    public DriverProfile onboard(User user, DriverDtos.OnboardRequest request) {
        if (!user.getRoles().contains(Role.DRIVER)) throw new BusinessException("Only drivers can onboard");
        DriverProfile driver = drivers.findByUser(user).orElseGet(DriverProfile::new);
        driver.setUser(user);
        driver.setLicenseNumber(request.licenseNumber());
        DriverProfile saved = drivers.save(driver);

        Vehicle vehicle = vehicles.findByDriver(saved).orElseGet(Vehicle::new);
        vehicle.setDriver(saved);
        vehicle.setVehicleType(request.vehicleType());
        vehicle.setRegistrationNumber(request.vehicleRegistrationNumber());
        vehicle.setInsurancePolicyNumber(request.insurancePolicyNumber());
        vehicle.setModel(request.model());
        vehicle.setActive(true);
        vehicles.save(vehicle);
        return saved;
    }

    public DriverProfile availability(User user, DriverDtos.AvailabilityRequest request) {
        DriverProfile driver = driverFor(user);
        if (request.available() || request.online()) {
            if (driver.getVerificationStatus() != DriverVerificationStatus.APPROVED
                    || !driver.isAdminApproved()
                    || driver.getAdminApprovalStatus() != AdminApprovalStatus.APPROVED
                    || driver.getKycStatus() != KycStatus.APPROVED
                    || user.getAccountStatus() != AccountStatus.ACTIVE) {
                throw new BusinessException("Your documents must be approved by Admin before going active.");
            }
        }
        driver.setAvailable(request.available());
        driver.setOnline(request.online());
        return drivers.save(driver);
    }

    public void updateLocation(User user, DriverDtos.LocationRequest request) {
        DriverProfile driver = driverFor(user);
        redis.opsForValue().set("driver:location:" + driver.getId(), request.latitude() + "," + request.longitude());
    }

    public List<DriverDtos.DriverResponse> nearby(VehicleType type) {
        return drivers.findAvailableApprovedDrivers().stream()
                .filter(driver -> vehicles.findByDriverAndActiveTrue(driver).map(v -> v.getVehicleType() == type).orElse(false))
                .map(this::response)
                .toList();
    }

    public List<?> earnings(User user) {
        return earnings.findByDriverOrderByCreatedAtDesc(driverFor(user));
    }

    public DriverDtos.VerificationStatusResponse verificationStatus(User user) {
        DriverProfile driver = driverFor(user);
        return new DriverDtos.VerificationStatusResponse(driver.getId(), driver.getVerificationStatus(),
                driver.getVerificationRejectionReason(), documentsComplete(driver),
                driver.getVerificationStatus() == DriverVerificationStatus.APPROVED);
    }

    public DriverProfile approve(UUID id) {
        DriverProfile driver = drivers.findById(id)
                .orElseThrow(() -> new BusinessException("Driver not found", HttpStatus.NOT_FOUND));
        driver.setKycStatus(KycStatus.APPROVED);
        driver.setAdminApproved(true);
        driver.setAdminApprovalStatus(AdminApprovalStatus.APPROVED);
        driver.setVerificationStatus(DriverVerificationStatus.APPROVED);
        driver.setVerificationRejectionReason(null);
        driver.setAvailable(false);
        driver.setOnline(false);
        return drivers.save(driver);
    }

    public DriverProfile driverFor(User user) {
        return drivers.findByUser(user)
                .orElseThrow(() -> new BusinessException("Driver profile not found", HttpStatus.FORBIDDEN));
    }

    public DriverDtos.DriverResponse response(DriverProfile driver) {
        VehicleType type = vehicles.findByDriver(driver).map(Vehicle::getVehicleType).orElse(null);
        return new DriverDtos.DriverResponse(driver.getId(), driver.getUser().getFullName(), type, driver.isAvailable(), driver.isOnline(),
                driver.isAdminApproved(), driver.getKycStatus(), driver.getAverageRating(), driver.getCompletedRides());
    }

    private AuthDtos.AuthResponse tokens(User user) {
        return new AuthDtos.AuthResponse(jwtService.accessToken(user), jwtService.refreshToken(user));
    }

    private String last4(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        String digits = value.replaceAll("\\D", "");
        if (digits.length() <= 4) {
            return digits;
        }
        return digits.substring(digits.length() - 4);
    }

    private boolean documentsComplete(DriverProfile driver) {
        return (hasValue(driver.getProfilePhotoStorageKey()) || hasValue(driver.getProfilePhotoData()))
                && (hasValue(driver.getAadhaarStorageKey()) || hasValue(driver.getAadhaarDocumentData()))
                && (hasValue(driver.getLicenseStorageKey()) || hasValue(driver.getLicenseDocumentData()))
                && (hasValue(driver.getVehicleDocumentStorageKey()) || hasValue(driver.getVehicleDocumentData()))
                && (hasValue(driver.getInsuranceDocumentStorageKey()) || hasValue(driver.getInsuranceDocumentData()));
    }

    private boolean hasValue(String value) {
        return value != null && !value.isBlank();
    }

    private void applyIfPresent(String value, java.util.function.Consumer<String> setter) {
        if (hasValue(value)) {
            setter.accept(value);
        }
    }

    private void ensureDocumentSubmissionAllowed(DriverProfile driver) {
        if (driver.getVerificationStatus() != DriverVerificationStatus.INCOMPLETE
                && driver.getVerificationStatus() != DriverVerificationStatus.REJECTED
                && driver.getVerificationStatus() != DriverVerificationStatus.RESUBMISSION_REQUIRED) {
            throw new BusinessException("Documents cannot be re-submitted unless Admin requests re-submission.");
        }
    }
}
