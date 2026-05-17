package com.shego.delivery;

import com.shego.common.ApiResponse;
import com.shego.exception.BusinessException;
import com.shego.rider.RiderProfile;
import com.shego.rider.RiderProfileRepository;
import com.shego.user.CurrentUserService;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
public class DeliveryController {
    private final DeliveryRequestRepository deliveries;
    private final RiderProfileRepository riders;
    private final CurrentUserService currentUserService;

    public DeliveryController(DeliveryRequestRepository deliveries, RiderProfileRepository riders, CurrentUserService currentUserService) {
        this.deliveries = deliveries;
        this.riders = riders;
        this.currentUserService = currentUserService;
    }

    @PostMapping("/api/deliveries")
    ApiResponse<DeliveryDtos.DeliveryResponse> create(@RequestBody DeliveryDtos.CreateRequest request) {
        RiderProfile rider = riders.findByUser(currentUserService.current())
                .orElseThrow(() -> new BusinessException("Rider profile not found", HttpStatus.FORBIDDEN));
        DeliveryRequest delivery = new DeliveryRequest();
        delivery.setRequestedBy(rider);
        delivery.setCategory(request.category());
        delivery.setPickupAddress(request.pickupAddress());
        delivery.setDropAddress(request.dropAddress());
        delivery.setItemDescription(request.itemDescription());
        return ApiResponse.ok("Delivery request created", DeliveryDtos.DeliveryResponse.from(deliveries.save(delivery)));
    }

    @GetMapping("/api/deliveries/me")
    ApiResponse<List<DeliveryDtos.DeliveryResponse>> mine() {
        RiderProfile rider = riders.findByUser(currentUserService.current())
                .orElseThrow(() -> new BusinessException("Rider profile not found", HttpStatus.FORBIDDEN));
        return ApiResponse.ok("My deliveries", deliveries.findByRequestedByOrderByCreatedAtDesc(rider).stream().map(DeliveryDtos.DeliveryResponse::from).toList());
    }
}
