package com.shego.location;

import com.shego.common.ApiResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
public class LocationController {
    private final LocationService locationService;

    public LocationController(LocationService locationService) {
        this.locationService = locationService;
    }

    @GetMapping("/api/rides/{rideId}/locations")
    ApiResponse<List<RideLocation>> history(@PathVariable UUID rideId) {
        return ApiResponse.ok("Ride location history", locationService.history(rideId));
    }
}
