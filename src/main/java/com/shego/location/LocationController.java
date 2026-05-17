package com.shego.location;

import com.shego.common.ApiResponse;
import com.shego.user.CurrentUserService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
public class LocationController {
    private final LocationService locationService;
    private final CurrentUserService currentUserService;

    public LocationController(LocationService locationService, CurrentUserService currentUserService) {
        this.locationService = locationService;
        this.currentUserService = currentUserService;
    }

    @GetMapping("/api/rides/{rideId}/locations")
    ApiResponse<List<RideLocation>> history(@PathVariable UUID rideId) {
        return ApiResponse.ok("Ride location history", locationService.history(rideId));
    }

    @GetMapping("/api/locations/saved")
    ApiResponse<List<LocationDtos.LocationResponse>> saved() {
        return ApiResponse.ok("Saved locations", locationService.saved(currentUserService.current()));
    }

    @PostMapping("/api/locations/saved")
    ApiResponse<LocationDtos.LocationResponse> saveLocation(@RequestBody LocationDtos.SavedLocationRequest request) {
        return ApiResponse.ok("Saved location created", locationService.saveLocation(currentUserService.current(), request));
    }

    @GetMapping("/api/locations/recent")
    ApiResponse<List<LocationDtos.LocationResponse>> recent() {
        return ApiResponse.ok("Recent location searches", locationService.recent(currentUserService.current()));
    }

    @PostMapping("/api/locations/recent")
    ApiResponse<LocationDtos.LocationResponse> saveRecent(@RequestBody LocationDtos.RecentLocationRequest request) {
        return ApiResponse.ok("Recent location search saved", locationService.saveRecent(currentUserService.current(), request));
    }

    @PostMapping("/api/directions/route")
    ApiResponse<LocationDtos.DirectionsResponse> route(@RequestBody LocationDtos.DirectionsRequest request) {
        return ApiResponse.ok("Route estimate", locationService.route(request));
    }

    @GetMapping("/api/rides/{rideId}/route-snapshot")
    ApiResponse<LocationDtos.RouteSnapshotResponse> routeSnapshot(@PathVariable UUID rideId) {
        return ApiResponse.ok("Ride route snapshot", locationService.routeSnapshot(rideId));
    }
}
