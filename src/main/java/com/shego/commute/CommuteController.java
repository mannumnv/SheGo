package com.shego.commute;

import com.shego.common.ApiResponse;
import com.shego.common.CommuteStatus;
import com.shego.driver.DriverProfileRepository;
import com.shego.exception.BusinessException;
import com.shego.rider.RiderProfile;
import com.shego.rider.RiderProfileRepository;
import com.shego.user.CurrentUserService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
public class CommuteController {
    private final CommuteScheduleRepository schedules;
    private final RiderProfileRepository riders;
    private final DriverProfileRepository drivers;
    private final CurrentUserService currentUserService;

    public CommuteController(CommuteScheduleRepository schedules, RiderProfileRepository riders,
                             DriverProfileRepository drivers, CurrentUserService currentUserService) {
        this.schedules = schedules;
        this.riders = riders;
        this.drivers = drivers;
        this.currentUserService = currentUserService;
    }

    @PostMapping("/api/commutes")
    ApiResponse<CommuteDtos.ScheduleResponse> create(@Valid @RequestBody CommuteDtos.ScheduleRequest request) {
        RiderProfile rider = riders.findByUser(currentUserService.current()).orElseThrow(() -> new BusinessException("Rider profile not found"));
        CommuteSchedule schedule = new CommuteSchedule();
        schedule.setRider(rider);
        schedule.setCommuteType(request.commuteType());
        schedule.setFrequency(request.frequency());
        schedule.setVehicleType(request.vehicleType());
        schedule.setPickupAddress(request.pickupAddress());
        schedule.setDropAddress(request.dropAddress());
        schedule.setPickupLat(request.pickupLat());
        schedule.setPickupLng(request.pickupLng());
        schedule.setDropLat(request.dropLat());
        schedule.setDropLng(request.dropLng());
        schedule.setPickupTime(request.pickupTime());
        if (request.preferredDriverId() != null) {
            schedule.setPreferredDriver(drivers.findById(request.preferredDriverId()).orElseThrow());
        }
        return ApiResponse.ok("Commute scheduled", CommuteDtos.ScheduleResponse.from(schedules.save(schedule)));
    }

    @GetMapping("/api/commutes/me")
    ApiResponse<List<CommuteDtos.ScheduleResponse>> mine() {
        RiderProfile rider = riders.findByUser(currentUserService.current()).orElseThrow();
        return ApiResponse.ok("My commutes", schedules.findByRiderOrderByCreatedAtDesc(rider).stream().map(CommuteDtos.ScheduleResponse::from).toList());
    }

    @PostMapping("/api/commutes/{id}/pause")
    ApiResponse<CommuteDtos.ScheduleResponse> pause(@PathVariable UUID id) {
        CommuteSchedule schedule = schedules.findById(id).orElseThrow();
        schedule.setStatus(CommuteStatus.PAUSED);
        return ApiResponse.ok("Commute paused", CommuteDtos.ScheduleResponse.from(schedules.save(schedule)));
    }

    @PostMapping("/api/commutes/{id}/cancel")
    ApiResponse<CommuteDtos.ScheduleResponse> cancel(@PathVariable UUID id) {
        CommuteSchedule schedule = schedules.findById(id).orElseThrow();
        schedule.setStatus(CommuteStatus.CANCELLED);
        return ApiResponse.ok("Commute cancelled", CommuteDtos.ScheduleResponse.from(schedules.save(schedule)));
    }
}
