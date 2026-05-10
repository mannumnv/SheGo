package com.shego.sos;

import com.shego.common.SosStatus;

import java.util.UUID;

public class SosDtos {
    public record TriggerRequest(UUID rideId, double latitude, double longitude, String message) {
    }

    public record ResolveRequest(String notes) {
    }

    public record SosResponse(UUID id, UUID rideId, SosStatus status, double latitude, double longitude, String message) {
        static SosResponse from(SosAlert alert) {
            return new SosResponse(alert.getId(), alert.getRide() == null ? null : alert.getRide().getId(),
                    alert.getStatus(), alert.getLatitude(), alert.getLongitude(), alert.getMessage());
        }
    }
}
