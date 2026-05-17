package com.shego.location;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;

@Service
public class LocalDirectionsService implements DirectionsService {
    private final String googleApiKey;

    public LocalDirectionsService(@Value("${shego.maps.google-api-key:}") String googleApiKey) {
        this.googleApiKey = googleApiKey == null ? "" : googleApiKey.trim();
    }

    @Override
    public LocationDtos.DirectionsResponse route(LocationDtos.DirectionsRequest request) {
        double distance = distanceKm(request.pickupLat(), request.pickupLng(), request.dropLat(), request.dropLng());
        int eta = Math.max(5, (int) Math.ceil(distance * 4));
        BigDecimal baseFare = BigDecimal.valueOf(25);
        BigDecimal distanceFare = BigDecimal.valueOf(distance).multiply(BigDecimal.valueOf(12)).setScale(2, RoundingMode.HALF_UP);
        BigDecimal timeFare = BigDecimal.valueOf(Math.max(0, eta - 5)).multiply(BigDecimal.valueOf(1.5)).setScale(2, RoundingMode.HALF_UP);
        BigDecimal platformFee = BigDecimal.valueOf(5);
        BigDecimal surgeFee = BigDecimal.ZERO;
        BigDecimal total = baseFare.add(distanceFare).add(timeFare).add(platformFee).add(surgeFee).setScale(2, RoundingMode.HALF_UP);
        String provider = googleApiKey.isBlank() ? "LOCAL_MOCK" : "GOOGLE_DIRECTIONS_READY";
        List<LocationDtos.RoutePoint> points = List.of(
                new LocationDtos.RoutePoint(request.pickupLat(), request.pickupLng()),
                new LocationDtos.RoutePoint(request.dropLat(), request.dropLng())
        );
        return new LocationDtos.DirectionsResponse(provider, distance, eta, encodeMockPolyline(points), points,
                new LocationDtos.FareBreakdown(baseFare, distanceFare, timeFare, platformFee, surgeFee, total));
    }

    private String encodeMockPolyline(List<LocationDtos.RoutePoint> points) {
        return points.stream()
                .map(point -> point.latitude() + "," + point.longitude())
                .reduce((left, right) -> left + "|" + right)
                .orElse("");
    }

    private double distanceKm(double lat1, double lon1, double lat2, double lon2) {
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLon / 2) * Math.sin(dLon / 2);
        return BigDecimal.valueOf(6371 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a)))
                .setScale(2, RoundingMode.HALF_UP)
                .doubleValue();
    }
}
