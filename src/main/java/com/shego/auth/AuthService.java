package com.shego.auth;

import com.shego.common.AccountStatus;
import com.shego.common.Role;
import com.shego.config.JwtService;
import com.shego.exception.BusinessException;
import com.shego.rider.RiderProfile;
import com.shego.rider.RiderProfileRepository;
import com.shego.user.User;
import com.shego.user.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.core.env.Environment;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.Duration;
import java.util.Arrays;
import java.util.Set;

@Service
public class AuthService {
    private static final Logger log = LoggerFactory.getLogger(AuthService.class);

    private final UserRepository users;
    private final RiderProfileRepository riders;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;
    private final JwtService jwtService;
    private final StringRedisTemplate redis;
    private final Environment environment;
    private final SecureRandom random = new SecureRandom();

    public AuthService(UserRepository users, RiderProfileRepository riders, PasswordEncoder passwordEncoder,
                       AuthenticationManager authenticationManager, JwtService jwtService, StringRedisTemplate redis,
                       Environment environment) {
        this.users = users;
        this.riders = riders;
        this.passwordEncoder = passwordEncoder;
        this.authenticationManager = authenticationManager;
        this.jwtService = jwtService;
        this.redis = redis;
        this.environment = environment;
    }

    @Transactional
    public AuthDtos.AuthResponse register(AuthDtos.RegisterRequest request) {
        if (users.existsByMobileNumber(request.mobileNumber())) {
            throw new BusinessException("Mobile number already registered");
        }
        if (request.roles().contains(Role.DRIVER) && request.roles().contains(Role.RIDER)) {
            throw new BusinessException("Register as rider or driver separately");
        }
        User user = new User();
        user.setFullName(request.fullName());
        user.setMobileNumber(request.mobileNumber());
        user.setEmail(request.email());
        user.setRoles(request.roles());
        user.setPasswordHash(passwordEncoder.encode(request.password() == null ? request.mobileNumber() : request.password()));
        user.setAccountStatus(request.roles().contains(Role.ADMIN) || request.roles().contains(Role.SUPPORT) ? AccountStatus.ACTIVE : AccountStatus.PENDING);
        User saved = users.save(user);
        if (request.roles().equals(Set.of(Role.RIDER))) {
            RiderProfile profile = new RiderProfile();
            profile.setUser(saved);
            riders.save(profile);
        }
        return tokens(saved);
    }

    public AuthDtos.AuthResponse login(AuthDtos.LoginRequest request) {
        User user = findByIdentifier(request.mobileNumber()).orElseThrow(() -> new BusinessException("Invalid credentials"));
        authenticationManager.authenticate(new UsernamePasswordAuthenticationToken(user.getMobileNumber(), request.password()));
        return tokens(user);
    }

    public void sendOtp(AuthDtos.OtpRequest request) {
        String rateKey = "otp:rate:" + request.mobileNumber();
        Long attempts = redis.opsForValue().increment(rateKey);
        if (attempts != null && attempts == 1) {
            redis.expire(rateKey, Duration.ofMinutes(10));
        }
        if (attempts != null && attempts > 5) {
            throw new BusinessException("Too many OTP requests. Try again later.");
        }
        String otp = String.valueOf(100000 + random.nextInt(900000));
        redis.opsForValue().set("otp:" + request.mobileNumber(), passwordEncoder.encode(otp), Duration.ofMinutes(5));
        // Production: send this OTP using SMS provider; keep logs redacted.
    }

    public AuthDtos.AuthResponse verifyOtp(AuthDtos.OtpVerifyRequest request) {
        User user = users.findByMobileNumber(request.mobileNumber()).orElseThrow(() -> new BusinessException("User not found"));
        String storedHash = redis.opsForValue().get("otp:" + request.mobileNumber());
        if (storedHash == null || !passwordEncoder.matches(request.otp(), storedHash)) {
            throw new BusinessException("Invalid or expired OTP");
        }
        redis.delete("otp:" + request.mobileNumber());
        return tokens(user);
    }

    public AuthDtos.AuthResponse refresh(AuthDtos.RefreshTokenRequest request) {
        jwtService.valid(request.refreshToken());
        String mobile = jwtService.subject(request.refreshToken());
        User user = users.findByMobileNumber(mobile).orElseThrow();
        return tokens(user);
    }

    public AuthDtos.ForgotPasswordSendOtpResponse sendForgotPasswordOtp(AuthDtos.ForgotPasswordSendOtpRequest request) {
        String identifier = request.identifier().trim();
        String rateKey = "forgot:send-rate:" + identifier;
        Long attempts = redis.opsForValue().increment(rateKey);
        if (attempts != null && attempts == 1) {
            redis.expire(rateKey, Duration.ofMinutes(10));
        }
        if (attempts != null && attempts > 5) {
            throw new BusinessException("Too many OTP requests. Try again later.");
        }

        String devOtp = null;
        if (findByIdentifier(identifier).isPresent()) {
            String otp = String.valueOf(100000 + random.nextInt(900000));
            redis.opsForValue().set(forgotOtpKey(identifier), passwordEncoder.encode(otp), Duration.ofMinutes(5));
            redis.delete(forgotVerifiedKey(identifier));
            if (isLocalOrDev()) {
                devOtp = otp;
                log.info("Local/dev forgot password OTP for identifier {} is {}", identifier, otp);
            }
        }
        return new AuthDtos.ForgotPasswordSendOtpResponse("If the account exists, an OTP has been sent.", devOtp);
    }

    public AuthDtos.ForgotPasswordVerifyOtpResponse verifyForgotPasswordOtp(AuthDtos.ForgotPasswordVerifyOtpRequest request) {
        verifyForgotOtpOrThrow(request.identifier().trim(), request.otp().trim());
        redis.opsForValue().set(forgotVerifiedKey(request.identifier().trim()), "true", Duration.ofMinutes(10));
        return new AuthDtos.ForgotPasswordVerifyOtpResponse(true);
    }

    @Transactional
    public void resetForgotPassword(AuthDtos.ForgotPasswordResetRequest request) {
        String identifier = request.identifier().trim();
        String otp = request.otp().trim();
        validateStrongPassword(request.newPassword());
        verifyForgotOtpOrThrow(identifier, otp);
        String verified = redis.opsForValue().get(forgotVerifiedKey(identifier));
        if (!"true".equals(verified)) {
            throw new BusinessException("OTP verification is required before password reset");
        }
        User user = findByIdentifier(identifier).orElseThrow(() -> new BusinessException("Invalid or expired OTP"));
        user.setPasswordHash(passwordEncoder.encode(request.newPassword()));
        users.save(user);
        redis.delete(forgotOtpKey(identifier));
        redis.delete(forgotVerifiedKey(identifier));
    }

    private AuthDtos.AuthResponse tokens(User user) {
        return new AuthDtos.AuthResponse(jwtService.accessToken(user), jwtService.refreshToken(user));
    }

    private void verifyForgotOtpOrThrow(String identifier, String otp) {
        String retryKey = "forgot:retry:" + identifier;
        Long retries = redis.opsForValue().increment(retryKey);
        if (retries != null && retries == 1) {
            redis.expire(retryKey, Duration.ofMinutes(5));
        }
        if (retries != null && retries > 5) {
            throw new BusinessException("Too many OTP verification attempts. Try again later.");
        }
        String storedHash = redis.opsForValue().get(forgotOtpKey(identifier));
        if (storedHash == null || !passwordEncoder.matches(otp, storedHash) || findByIdentifier(identifier).isEmpty()) {
            throw new BusinessException("Invalid or expired OTP");
        }
    }

    private java.util.Optional<User> findByIdentifier(String identifier) {
        return users.findByMobileNumber(identifier)
                .or(() -> users.findByEmail(identifier));
    }

    private String forgotOtpKey(String identifier) {
        return "forgot:otp:" + identifier;
    }

    private String forgotVerifiedKey(String identifier) {
        return "forgot:verified:" + identifier;
    }

    private boolean isLocalOrDev() {
        Set<String> profiles = Set.copyOf(Arrays.asList(environment.getActiveProfiles()));
        return profiles.isEmpty() || profiles.contains("local") || profiles.contains("dev");
    }

    private void validateStrongPassword(String password) {
        if (password == null || password.length() < 8 ||
                !password.matches(".*[A-Z].*") ||
                !password.matches(".*[a-z].*") ||
                !password.matches(".*\\d.*")) {
            throw new BusinessException("Password must be at least 8 characters and include uppercase, lowercase, and number");
        }
    }
}
