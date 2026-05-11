package com.shego.ride;

import com.shego.common.BaseEntity;
import com.shego.common.PaymentMethod;
import com.shego.common.RideStatus;
import com.shego.common.VehicleType;
import com.shego.driver.DriverProfile;
import com.shego.rider.RiderProfile;
import com.shego.vehicle.Vehicle;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.ManyToOne;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;

@Getter
@Setter
@NoArgsConstructor
@Entity
public class Ride extends BaseEntity {
    @ManyToOne(optional = false)
    private RiderProfile rider;

    @ManyToOne
    private DriverProfile driver;

    @ManyToOne
    private Vehicle vehicle;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private VehicleType vehicleType;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private RideStatus status = RideStatus.REQUESTED;

    private double pickupLat;
    private double pickupLng;
    private double dropLat;
    private double dropLng;
    private String pickupAddress;
    private String dropAddress;
    private double distanceKm;
    private int etaMinutes;
    private BigDecimal estimatedFare;
    private BigDecimal finalFare;
    private String vehicleRegistrationSnapshot;
    private String vehicleModelSnapshot;
    @Column(name = "start_otp")
    private String startOtpHash;
    private Instant startOtpExpiresAt;
    private int startOtpRetryCount;
    private String completionOtp;
    private boolean guardianModeEnabled;
    private boolean lateNight;

    @Enumerated(EnumType.STRING)
    private PaymentMethod paymentMethod = PaymentMethod.CASH;

    private Instant acceptedAt;
    private Instant assignedAt;
    private Instant driverReachedAt;
    private Instant riderBoardedAt;
    private Instant startedAt;
    private Instant completedAt;
    private Instant rideCompletedAt;
    private Instant cancelledAt;
}
