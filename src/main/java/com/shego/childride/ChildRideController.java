package com.shego.childride;

import com.shego.common.ApiResponse;
import com.shego.exception.BusinessException;
import com.shego.rider.RiderProfileRepository;
import com.shego.user.CurrentUserService;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
public class ChildRideController {
    private final ChildRideRepository childRides;
    private final RiderProfileRepository riders;
    private final CurrentUserService currentUserService;

    public ChildRideController(ChildRideRepository childRides, RiderProfileRepository riders, CurrentUserService currentUserService) {
        this.childRides = childRides;
        this.riders = riders;
        this.currentUserService = currentUserService;
    }

    @PostMapping("/api/child-rides/book")
    ApiResponse<ChildRide> book(@RequestBody ChildRideDtos.BookRequest request) {
        ChildRide childRide = new ChildRide();
        childRide.setGuardian(riders.findByUser(currentUserService.current())
                .orElseThrow(() -> new BusinessException("Rider profile not found", HttpStatus.FORBIDDEN)));
        childRide.setChildName(request.childName());
        childRide.setScheduledAt(request.scheduledAt());
        childRide.setPickupOtp(String.valueOf((int) (Math.random() * 9000) + 1000));
        childRide.setDropOtp(String.valueOf((int) (Math.random() * 9000) + 1000));
        childRide.setStatus("SCHEDULED");
        return ApiResponse.ok("Child ride booked", childRides.save(childRide));
    }

    @PostMapping("/api/child-rides/{id}/pickup-verify")
    ApiResponse<ChildRide> pickup(@PathVariable UUID id, @RequestBody ChildRideDtos.VerifyRequest request) {
        ChildRide ride = childRides.findById(id)
                .orElseThrow(() -> new BusinessException("Child ride not found", HttpStatus.NOT_FOUND));
        if (!ride.getPickupOtp().equals(request.otp())) throw new BusinessException("Invalid pickup OTP");
        ride.setStatus("PICKED_UP");
        return ApiResponse.ok("Pickup verified", childRides.save(ride));
    }

    @PostMapping("/api/child-rides/{id}/drop-verify")
    ApiResponse<ChildRide> drop(@PathVariable UUID id, @RequestBody ChildRideDtos.VerifyRequest request) {
        ChildRide ride = childRides.findById(id)
                .orElseThrow(() -> new BusinessException("Child ride not found", HttpStatus.NOT_FOUND));
        if (!ride.getDropOtp().equals(request.otp())) throw new BusinessException("Invalid drop OTP");
        ride.setStatus("DROPPED");
        return ApiResponse.ok("Drop verified", childRides.save(ride));
    }

    @GetMapping("/api/child-rides/history")
    ApiResponse<List<ChildRide>> history() {
        return ApiResponse.ok("Child ride history", childRides.findByGuardianOrderByCreatedAtDesc(
                riders.findByUser(currentUserService.current())
                        .orElseThrow(() -> new BusinessException("Rider profile not found", HttpStatus.FORBIDDEN))));
    }
}
