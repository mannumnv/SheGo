package com.shego.location;

import com.shego.common.SavedLocationType;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

public class LocationDtos {
    public record LiveLocationMessage(UUID rideId, UUID userId, double latitude, double longitude, double speedKmph, double bearing) {
    }

    public record SavedLocationRequest(SavedLocationType type, String label, String address, double latitude, double longitude) {
    }

    public record RecentLocationRequest(String queryText, String address, double latitude, double longitude) {
    }

    public record LocationResponse(UUID id, String type, String label, String address, double latitude, double longitude) {
        static LocationResponse from(SavedLocation location) {
            return new LocationResponse(location.getId(), location.getType().name(), location.getLabel(), location.getAddress(),
                    location.getLatitude(), location.getLongitude());
        }

        static LocationResponse from(RecentLocationSearch location) {
            return new LocationResponse(location.getId(), "RECENT", location.getQueryText(), location.getAddress(),
                    location.getLatitude(), location.getLongitude());
        }
    }

    public record DirectionsRequest(double pickupLat, double pickupLng, double dropLat, double dropLng,
                                    String pickupAddress, String dropAddress) {
    }

    public record RoutePoint(double latitude, double longitude) {
    }

    public record FareBreakdown(BigDecimal baseFare, BigDecimal distanceFare, BigDecimal timeFare,
                                BigDecimal platformFee, BigDecimal surgeFee, BigDecimal totalFare) {
    }

    public record DirectionsResponse(String provider, double distanceKm, int etaMinutes, String encodedPolyline,
                                     List<RoutePoint> polylinePoints, FareBreakdown fareBreakdown) {
    }

    public record RouteSnapshotResponse(UUID rideId, String provider, BigDecimal distanceKm, Integer etaMinutes,
                                        String encodedPolyline) {
        static RouteSnapshotResponse from(RideRouteSnapshot snapshot) {
            return new RouteSnapshotResponse(snapshot.getRide().getId(), snapshot.getProvider(), snapshot.getDistanceKm(),
                    snapshot.getEtaMinutes(), snapshot.getEncodedPolyline());
        }
    }
}
