package com.shego.ride;

import com.shego.common.ApiResponse;
import com.shego.user.CurrentUserService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/rides")
public class RideController {
    private final RideService rideService;
    private final CurrentUserService currentUserService;

    public RideController(RideService rideService, CurrentUserService currentUserService) {
        this.rideService = rideService;
        this.currentUserService = currentUserService;
    }

    @PostMapping("/estimate")
    ApiResponse<RideDtos.EstimateResponse> estimate(@RequestBody RideDtos.EstimateRequest request) {
        return ApiResponse.ok("Fare estimate", rideService.estimate(request));
    }

    @PostMapping("/book")
    ApiResponse<RideDtos.RideResponse> book(@RequestBody RideDtos.BookRequest request) {
        return ApiResponse.ok("Ride booked", RideDtos.RideResponse.from(rideService.book(currentUserService.current(), request)));
    }

    @PostMapping("/{id}/accept")
    ApiResponse<RideDtos.RideAcceptedResponse> accept(@PathVariable UUID id) {
        return ApiResponse.ok("Ride accepted", rideService.acceptedResponse(rideService.accept(currentUserService.current(), id)));
    }

    @PostMapping("/{id}/reject")
    ApiResponse<RideDtos.RideResponse> reject(@PathVariable UUID id) {
        return ApiResponse.ok("Ride rejected", RideDtos.RideResponse.from(rideService.reject(currentUserService.current(), id)));
    }

    @PostMapping("/{id}/arrive")
    ApiResponse<RideDtos.RideDetailsResponse> arrive(@PathVariable UUID id) {
        return ApiResponse.ok("Driver reached pickup", rideService.details(currentUserService.current(),
                rideService.arrive(currentUserService.current(), id).getId()));
    }

    @PostMapping("/{id}/start")
    ApiResponse<RideDtos.RideStartResponse> start(@PathVariable UUID id, @RequestBody RideDtos.RideStartOtpRequest request) {
        return ApiResponse.ok("Ride started", rideService.start(currentUserService.current(), id, request.otp()));
    }

    @PostMapping("/{id}/complete")
    ApiResponse<RideDtos.RideResponse> complete(@PathVariable UUID id) {
        return ApiResponse.ok("Ride completed", RideDtos.RideResponse.from(rideService.complete(id)));
    }

    @PostMapping("/{id}/cancel")
    ApiResponse<RideDtos.RideResponse> cancel(@PathVariable UUID id) {
        return ApiResponse.ok("Ride cancelled", RideDtos.RideResponse.from(rideService.cancel(id)));
    }

    @GetMapping("/{id}")
    ApiResponse<RideDtos.RideDetailsResponse> get(@PathVariable UUID id) {
        return ApiResponse.ok("Ride", rideService.details(currentUserService.current(), id));
    }

    @GetMapping("/history")
    ApiResponse<List<RideDtos.RideResponse>> history() {
        return ApiResponse.ok("Ride history", rideService.history(currentUserService.current()).stream().map(RideDtos.RideResponse::from).toList());
    }
}
