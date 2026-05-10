package com.shego.safety;

import com.shego.common.ApiResponse;
import com.shego.user.CurrentUserService;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
public class SafetyController {
    private final SafetyScoreService safety;
    private final CurrentUserService currentUserService;

    public SafetyController(SafetyScoreService safety, CurrentUserService currentUserService) {
        this.safety = safety;
        this.currentUserService = currentUserService;
    }

    @GetMapping("/api/safety/driver/{driverId}/score")
    ApiResponse<SafetyDtos.ScoreResponse> score(@PathVariable UUID driverId) {
        return ApiResponse.ok("Driver safety score", SafetyDtos.ScoreResponse.from(safety.get(driverId)));
    }

    @PostMapping("/api/safety/events")
    ApiResponse<SafetyEvent> event(@RequestBody SafetyDtos.EventRequest request) {
        return ApiResponse.ok("Safety event created", safety.event(currentUserService.current(), request));
    }

    @PreAuthorize("hasAnyRole('ADMIN','SUPPORT')")
    @GetMapping("/api/admin/safety/events")
    ApiResponse<List<SafetyEvent>> events() {
        return ApiResponse.ok("Safety events", safety.allEvents());
    }
}
