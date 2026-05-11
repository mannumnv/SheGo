package com.shego.ride;

import com.shego.common.RideStatus;
import com.shego.common.VehicleType;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

public class RideDtos {
    public record EstimateRequest(@NotNull VehicleType vehicleType, double pickupLat, double pickupLng, double dropLat, double dropLng) {
    }

    public record BookRequest(@NotNull VehicleType vehicleType, double pickupLat, double pickupLng, double dropLat, double dropLng,
                              String pickupAddress, String dropAddress) {
    }

    public record OtpRequest(String otp) {
    }

    public record RideStartOtpRequest(String otp) {
    }

    public record RideResponse(UUID id, RideStatus status, VehicleType vehicleType, UUID riderId, UUID driverId,
                               UUID vehicleId, String vehicleRegistrationSnapshot, String vehicleModelSnapshot,
                               BigDecimal estimatedFare, BigDecimal finalFare, boolean guardianModeEnabled, boolean lateNight) {
        public static RideResponse from(Ride ride) {
            return new RideResponse(ride.getId(), ride.getStatus(), ride.getVehicleType(), ride.getRider().getId(),
                    ride.getDriver() == null ? null : ride.getDriver().getId(),
                    ride.getVehicle() == null ? null : ride.getVehicle().getId(),
                    ride.getVehicleRegistrationSnapshot(), ride.getVehicleModelSnapshot(),
                    ride.getEstimatedFare(), ride.getFinalFare(),
                    ride.isGuardianModeEnabled(), ride.isLateNight());
        }
    }

    public record ParticipantDriverDetails(String fullName, String contactNumber, String profilePhotoUrl,
                                           VehicleType vehicleType, String vehicleRegistrationNumber, String vehicleModel) {
    }

    public record ParticipantRiderDetails(String fullName, String contactNumber, String profilePhotoUrl) {
    }

    public record RideDetailsResponse(UUID id, RideStatus status, VehicleType vehicleType, UUID riderId, UUID driverId,
                                      UUID vehicleId, ParticipantDriverDetails driver, ParticipantRiderDetails rider,
                                      String pickupAddress, String dropAddress, double pickupLat, double pickupLng,
                                      double dropLat, double dropLng, int etaMinutes, boolean guardianModeEnabled,
                                      boolean lateNight, String startOtp, Instant startOtpExpiresAt,
                                      Instant acceptedAt, Instant driverReachedAt, Instant startedAt) {
    }

    public record RideAcceptedResponse(UUID id, RideStatus status, RideDetailsResponse riderView,
                                       RideDetailsResponse driverView) {
    }

    public record RideStartResponse(UUID rideId, RideStatus status, Instant startedAt) {
    }

    public record EstimateResponse(double distanceKm, int etaMinutes, BigDecimal estimatedFare) {
    }
}
