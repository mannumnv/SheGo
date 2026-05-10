package com.shego.location;

import java.util.UUID;

public class LocationDtos {
    public record LiveLocationMessage(UUID rideId, UUID userId, double latitude, double longitude, double speedKmph, double bearing) {
    }
}
