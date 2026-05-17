package com.shego.rider;

import com.shego.auth.AuthDtos;
import com.shego.common.EligibilityValidationService;
import com.shego.common.KycStatus;
import com.shego.common.NotificationType;
import com.shego.common.Role;
import com.shego.config.JwtService;
import com.shego.exception.BusinessException;
import com.shego.notification.NotificationService;
import com.shego.user.User;
import com.shego.user.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Set;

@Service
public class RiderService {
    private final UserRepository users;
    private final RiderProfileRepository riders;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;
    private final JwtService jwtService;
    private final EligibilityValidationService eligibility;
    private final NotificationService notifications;

    public RiderService(UserRepository users, RiderProfileRepository riders, PasswordEncoder passwordEncoder,
                        AuthenticationManager authenticationManager, JwtService jwtService,
                        EligibilityValidationService eligibility, NotificationService notifications) {
        this.users = users;
        this.riders = riders;
        this.passwordEncoder = passwordEncoder;
        this.authenticationManager = authenticationManager;
        this.jwtService = jwtService;
        this.eligibility = eligibility;
        this.notifications = notifications;
    }

    @Transactional
    public AuthDtos.AuthResponse signup(RiderDtos.SignupRequest request) {
        if (users.existsByMobileNumber(request.mobileNumber())) {
            throw new BusinessException("Mobile number already registered");
        }
        var result = eligibility.validateRider(request.gender(), request.dateOfBirth(), request.riderAadhaarNumber(),
                request.guardianAadhaarNumber(), request.guardianMobileNumber(), request.guardianRelationship(),
                request.guardianConsent());

        User user = new User();
        user.setFullName(request.fullName());
        user.setMobileNumber(request.mobileNumber());
        user.setRoles(Set.of(Role.RIDER));
        user.setPasswordHash(passwordEncoder.encode(request.password() == null ? request.mobileNumber() : request.password()));
        user.setAccountStatus(result.accountStatus());
        user.setFemaleVerified(request.gender() == com.shego.common.Gender.FEMALE);
        User saved = users.save(user);

        RiderProfile profile = new RiderProfile();
        profile.setUser(saved);
        profile.setRiderGender(request.gender());
        profile.setRiderDateOfBirth(request.dateOfBirth());
        profile.setRiderAge(result.age());
        profile.setRiderAgeCategory(result.ageCategory());
        profile.setVerificationType(result.verificationType());
        profile.setAddress(request.address());
        profile.setProfilePhotoStorageKey(request.profilePhotoStorageKey());
        profile.setEmergencyContact(request.emergencyContact());
        profile.setGuardianName(request.guardianName());
        profile.setGuardianRelationship(request.guardianRelationship());
        profile.setGuardianMobileNumber(request.guardianMobileNumber());
        profile.setGuardianAadhaarEncrypted(request.guardianAadhaarNumber());
        profile.setGuardianAadhaarLast4(last4(request.guardianAadhaarNumber()));
        profile.setRiderAadhaarEncrypted(request.riderAadhaarNumber());
        profile.setRiderAadhaarLast4(last4(request.riderAadhaarNumber()));
        profile.setGuardianConsent(request.guardianConsent());
        profile.setKycStatus(result.verificationType() == null ? KycStatus.PENDING : KycStatus.PENDING);
        RiderProfile savedProfile = riders.save(profile);
        notifications.create(saved, Role.RIDER, NotificationType.PROFILE,
                "Complete your rider profile",
                "Add emergency contact, guardian details if needed, and payment setup for a smoother ride.",
                "RiderProfile", savedProfile.getId().toString(), "rider-profile",
                "rider-profile:" + savedProfile.getId());
        if (saved.getAccountStatus() != com.shego.common.AccountStatus.ACTIVE) {
            notifications.createForRole(Role.ADMIN, NotificationType.ACTION_REQUIRED,
                    "New rider signup pending review",
                    saved.getFullName() + " requires rider verification review.",
                    "RiderProfile", savedProfile.getId().toString(), "admin-rider-verification",
                    "admin-rider-signup:" + savedProfile.getId());
        }
        return tokens(saved);
    }

    public AuthDtos.AuthResponse login(RiderDtos.LoginRequest request) {
        authenticationManager.authenticate(new UsernamePasswordAuthenticationToken(request.mobileNumber(), request.password()));
        User user = users.findByMobileNumber(request.mobileNumber())
                .orElseThrow(() -> new BusinessException("Invalid credentials"));
        if (!user.getRoles().contains(Role.RIDER)) {
            throw new BusinessException("Rider account not found");
        }
        return tokens(user);
    }

    public RiderProfile profile(User user) {
        return riders.findByUser(user)
                .orElseThrow(() -> new BusinessException("Rider profile not found", HttpStatus.FORBIDDEN));
    }

    public RiderProfile verifyGuardian(User user, RiderDtos.GuardianVerificationRequest request) {
        RiderProfile profile = profile(user);
        profile.setGuardianAadhaarEncrypted(request.guardianAadhaarNumber());
        profile.setGuardianAadhaarLast4(last4(request.guardianAadhaarNumber()));
        profile.setGuardianMobileNumber(request.guardianMobileNumber());
        profile.setGuardianRelationship(request.guardianRelationship());
        profile.setGuardianConsent(request.guardianConsent());
        return riders.save(profile);
    }

    public RiderProfile active(User user, RiderDtos.ActiveRequest request) {
        RiderProfile profile = profile(user);
        profile.setActive(request.active());
        return riders.save(profile);
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

    private AuthDtos.AuthResponse tokens(User user) {
        return new AuthDtos.AuthResponse(jwtService.accessToken(user), jwtService.refreshToken(user));
    }
}
