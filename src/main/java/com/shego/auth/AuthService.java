package com.shego.auth;

import com.shego.common.AccountStatus;
import com.shego.common.Role;
import com.shego.config.JwtService;
import com.shego.exception.BusinessException;
import com.shego.rider.RiderProfile;
import com.shego.rider.RiderProfileRepository;
import com.shego.user.User;
import com.shego.user.UserRepository;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.Duration;
import java.util.Set;

@Service
public class AuthService {
    private final UserRepository users;
    private final RiderProfileRepository riders;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;
    private final JwtService jwtService;
    private final StringRedisTemplate redis;
    private final SecureRandom random = new SecureRandom();

    public AuthService(UserRepository users, RiderProfileRepository riders, PasswordEncoder passwordEncoder,
                       AuthenticationManager authenticationManager, JwtService jwtService, StringRedisTemplate redis) {
        this.users = users;
        this.riders = riders;
        this.passwordEncoder = passwordEncoder;
        this.authenticationManager = authenticationManager;
        this.jwtService = jwtService;
        this.redis = redis;
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
        authenticationManager.authenticate(new UsernamePasswordAuthenticationToken(request.mobileNumber(), request.password()));
        User user = users.findByMobileNumber(request.mobileNumber()).orElseThrow();
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

    private AuthDtos.AuthResponse tokens(User user) {
        return new AuthDtos.AuthResponse(jwtService.accessToken(user), jwtService.refreshToken(user));
    }
}
