package com.shego.ride;

import com.shego.common.RideStatus;
import com.shego.common.VehicleType;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.util.UUID;

public class RideDtos {
    public record EstimateRequest(@NotNull VehicleType vehicleType, double pickupLat, double pickupLng, double dropLat, double dropLng) {
    }

    public record BookRequest(@NotNull VehicleType vehicleType, double pickupLat, double pickupLng, double dropLat, double dropLng,
                              String pickupAddress, String dropAddress) {
    }

    public record OtpRequest(String otp) {
    }

    public record RideResponse(UUID id, RideStatus status, VehicleType vehicleType, UUID riderId, UUID driverId,
                               UUID vehicleId, String vehicleRegistrationSnapshot, String vehicleModelSnapshot,
                               BigDecimal estimatedFare, BigDecimal finalFare, boolean guardianModeEnabled, boolean lateNight) {
        static RideResponse from(Ride ride) {
            return new RideResponse(ride.getId(), ride.getStatus(), ride.getVehicleType(), ride.getRider().getId(),
                    ride.getDriver() == null ? null : ride.getDriver().getId(),
                    ride.getVehicle() == null ? null : ride.getVehicle().getId(),
                    ride.getVehicleRegistrationSnapshot(), ride.getVehicleModelSnapshot(),
                    ride.getEstimatedFare(), ride.getFinalFare(),
                    ride.isGuardianModeEnabled(), ride.isLateNight());
        }
    }

    public record EstimateResponse(double distanceKm, int etaMinutes, BigDecimal estimatedFare) {
    }
}
