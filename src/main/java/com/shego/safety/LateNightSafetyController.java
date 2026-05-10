package com.shego.safety;

import com.shego.common.ApiResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalTime;
import java.time.ZoneId;
import java.util.List;
import java.util.Map;

@RestController
public class LateNightSafetyController {
    @GetMapping("/api/safety/late-night-policy")
    ApiResponse<Map<String, Object>> policy() {
        LocalTime now = LocalTime.now(ZoneId.of("Asia/Kolkata"));
        boolean active = !now.isBefore(LocalTime.of(22, 0)) || now.isBefore(LocalTime.of(5, 0));
        return ApiResponse.ok("Late night safety policy", Map.of(
                "active", active,
                "window", "22:00-05:00 IST",
                "driverRules", List.of("KYC_APPROVED", "ADMIN_APPROVED", "HIGH_SAFETY_SCORE_PREFERRED", "HIGH_RATING_PREFERRED"),
                "riderRules", List.of("AUTO_SHARE_WITH_GUARDIAN", "ROUTE_DEVIATION_MONITORING", "UNUSUAL_STOP_ALERTS"),
                "mapSafetyHints", List.of("Prefer main roads", "Show nearby police stations", "Show nearby hospitals")
        ));
    }
}
