package com.shego.driver;

import com.shego.auth.AuthDtos;
import com.shego.common.ApiResponse;
import com.shego.common.VehicleType;
import com.shego.user.CurrentUserService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/drivers")
public class DriverController {
    private final DriverService driverService;
    private final CurrentUserService currentUserService;

    public DriverController(DriverService driverService, CurrentUserService currentUserService) {
        this.driverService = driverService;
        this.currentUserService = currentUserService;
    }

    @PostMapping("/onboard")
    ApiResponse<DriverDtos.DriverResponse> onboard(@Valid @RequestBody DriverDtos.OnboardRequest request) {
        return ApiResponse.ok("Driver onboarded", driverService.response(driverService.onboard(currentUserService.current(), request)));
    }

    @PostMapping("/signup")
    ApiResponse<AuthDtos.AuthResponse> signup(@Valid @RequestBody DriverDtos.SignupRequest request) {
        return ApiResponse.ok("Driver signup completed", driverService.signup(request));
    }

    @PostMapping("/login")
    ApiResponse<AuthDtos.AuthResponse> login(@Valid @RequestBody DriverDtos.LoginRequest request) {
        return ApiResponse.ok("Driver logged in", driverService.login(request));
    }

    @PostMapping("/upload-kyc")
    ApiResponse<DriverDtos.DriverProfileResponse> uploadKyc(@RequestBody DriverDtos.UploadKycRequest request) {
        return ApiResponse.ok("Driver KYC uploaded",
                DriverDtos.DriverProfileResponse.from(driverService.uploadKyc(currentUserService.current(), request)));
    }

    @GetMapping("/profile")
    ApiResponse<DriverDtos.DriverProfileResponse> profile() {
        return ApiResponse.ok("Driver profile",
                DriverDtos.DriverProfileResponse.from(driverService.driverFor(currentUserService.current())));
    }

    @PutMapping("/availability")
    ApiResponse<DriverDtos.DriverResponse> availability(@RequestBody DriverDtos.AvailabilityRequest request) {
        return ApiResponse.ok("Availability updated", driverService.response(driverService.availability(currentUserService.current(), request)));
    }

    @PutMapping("/location")
    ApiResponse<Void> location(@RequestBody DriverDtos.LocationRequest request) {
        driverService.updateLocation(currentUserService.current(), request);
        return ApiResponse.ok("Location updated", null);
    }

    @GetMapping("/nearby")
    ApiResponse<List<DriverDtos.DriverResponse>> nearby(@RequestParam(defaultValue = "SCOOTY") VehicleType vehicleType) {
        return ApiResponse.ok("Nearby drivers", driverService.nearby(vehicleType));
    }

    @GetMapping("/me/earnings")
    ApiResponse<List<?>> earnings() {
        return ApiResponse.ok("Driver earnings", (List<?>) driverService.earnings(currentUserService.current()));
    }
}
