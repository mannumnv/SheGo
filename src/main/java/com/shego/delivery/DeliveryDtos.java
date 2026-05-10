package com.shego.delivery;

import com.shego.common.DeliveryCategory;
import com.shego.common.DeliveryStatus;

import java.util.UUID;

public class DeliveryDtos {
    public record CreateRequest(DeliveryCategory category, String pickupAddress, String dropAddress, String itemDescription) {
    }

    public record DeliveryResponse(UUID id, DeliveryCategory category, DeliveryStatus status, String pickupAddress,
                                   String dropAddress, String itemDescription) {
        static DeliveryResponse from(DeliveryRequest request) {
            return new DeliveryResponse(request.getId(), request.getCategory(), request.getStatus(),
                    request.getPickupAddress(), request.getDropAddress(), request.getItemDescription());
        }
    }
}
