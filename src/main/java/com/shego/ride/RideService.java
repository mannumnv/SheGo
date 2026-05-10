package com.shego.ride;

import com.shego.common.AccountStatus;
import com.shego.common.KycStatus;
import com.shego.common.RideStatus;
import com.shego.driver.DriverProfile;
import com.shego.driver.DriverProfileRepository;
import com.shego.exception.BusinessException;
import com.shego.notification.NotificationService;
import com.shego.payment.DriverEarning;
import com.shego.payment.DriverEarningRepository;
import com.shego.rider.RiderProfile;
import com.shego.rider.RiderProfileRepository;
import com.shego.safety.SafetyScoreService;
import com.shego.user.User;
import com.shego.vehicle.Vehicle;
import com.shego.vehicle.VehicleRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalTime;
import java.time.ZoneId;
import java.util.List;
import java.util.UUID;

@Service
public class RideService {
    private static final List<RideStatus> ACTIVE = List.of(RideStatus.REQUESTED, RideStatus.ACCEPTED, RideStatus.DRIVER_ARRIVING, RideStatus.STARTED);
    private final RideRepository rides;
    private final RiderProfileRepository riders;
    private final DriverProfileRepository drivers;
    private final SafetyScoreService safetyScoreService;
    private final DriverEarningRepository earnings;
    private final NotificationService notifications;
    private final VehicleRepository vehicles;

    public RideService(RideRepository rides, RiderProfileRepository riders, DriverProfileRepository drivers,
                       SafetyScoreService safetyScoreService, DriverEarningRepository earnings,
                       NotificationService notifications, VehicleRepository vehicles) {
        this.rides = rides;
        this.riders = riders;
        this.drivers = drivers;
        this.safetyScoreService = safetyScoreService;
        this.earnings = earnings;
        this.notifications = notifications;
        this.vehicles = vehicles;
    }

    public RideDtos.EstimateResponse estimate(RideDtos.EstimateRequest request) {
        double distance = distanceKm(request.pickupLat(), request.pickupLng(), request.dropLat(), request.dropLng());
        BigDecimal fare = BigDecimal.valueOf(25 + distance * 12).setScale(2, RoundingMode.HALF_UP);
        return new RideDtos.EstimateResponse(distance, Math.max(5, (int) Math.ceil(distance * 4)), fare);
    }

    public Ride book(User user, RideDtos.BookRequest request) {
        RiderProfile rider = riders.findByUser(user).orElseThrow(() -> new BusinessException("Rider profile not found"));
        if (user.getAccountStatus() != AccountStatus.ACTIVE || rider.getKycStatus() != KycStatus.APPROVED) {
            throw new BusinessException("Only approved riders can book rides");
        }
        RideDtos.EstimateResponse estimate = estimate(new RideDtos.EstimateRequest(request.vehicleType(), request.pickupLat(), request.pickupLng(), request.dropLat(), request.dropLng()));
        Ride ride = new Ride();
        ride.setRider(rider);
        ride.setVehicleType(request.vehicleType());
        ride.setPickupLat(request.pickupLat());
        ride.setPickupLng(request.pickupLng());
        ride.setDropLat(request.dropLat());
        ride.setDropLng(request.dropLng());
        ride.setPickupAddress(request.pickupAddress());
        ride.setDropAddress(request.dropAddress());
        ride.setDistanceKm(estimate.distanceKm());
        ride.setEtaMinutes(estimate.etaMinutes());
        ride.setEstimatedFare(estimate.estimatedFare());
        ride.setStartOtp(String.valueOf((int) (Math.random() * 9000) + 1000));
        ride.setLateNight(isLateNight());
        ride.setGuardianModeEnabled(ride.isLateNight());
        Ride saved = rides.save(ride);
        notifications.create(user, "PUSH", "Ride requested", "Your SheGo ride request has been created.");
        return saved;
    }

    @Transactional
    public Ride accept(User user, UUID rideId) {
        DriverProfile driver = drivers.findByUser(user).orElseThrow(() -> new BusinessException("Driver profile not found"));
        if (!driver.isAdminApproved() || driver.getKycStatus() != KycStatus.APPROVED || user.getAccountStatus() != AccountStatus.ACTIVE) {
            throw new BusinessException("Only verified women drivers can accept rides");
        }
        if (!rides.findByDriverAndStatusIn(driver, ACTIVE).isEmpty()) {
            throw new BusinessException("Driver already has an active ride");
        }
        Ride ride = rides.findById(rideId).orElseThrow();
        Vehicle vehicle = vehicles.findByDriverAndActiveTrue(driver)
                .filter(v -> v.getVehicleType() == ride.getVehicleType())
                .orElseThrow(() -> new BusinessException("Driver does not have an active matching scooty/bike vehicle"));
        if (ride.getStatus() != RideStatus.REQUESTED) throw new BusinessException("Ride is not requestable");
        ride.setDriver(driver);
        ride.setVehicle(vehicle);
        ride.setVehicleRegistrationSnapshot(vehicle.getRegistrationNumber());
        ride.setVehicleModelSnapshot(vehicle.getModel());
        ride.setStatus(RideStatus.ACCEPTED);
        ride.setAcceptedAt(Instant.now());
        ride.setAssignedAt(ride.getAcceptedAt());
        driver.setAvailable(false);
        drivers.save(driver);
        Ride saved = rides.save(ride);
        notifications.create(ride.getRider().getUser(), "PUSH", "Ride accepted", "A verified SheGo driver accepted your ride.");
        return saved;
    }

    public Ride reject(User user, UUID rideId) {
        drivers.findByUser(user).orElseThrow(() -> new BusinessException("Driver profile not found"));
        Ride ride = rides.findById(rideId).orElseThrow();
        if (ride.getStatus() != RideStatus.REQUESTED) {
            throw new BusinessException("Only requested rides can be rejected");
        }
        return ride;
    }

    public Ride start(UUID rideId, String otp) {
        Ride ride = rides.findById(rideId).orElseThrow();
        if (ride.getStatus() != RideStatus.ACCEPTED && ride.getStatus() != RideStatus.DRIVER_ARRIVING) {
            throw new BusinessException("Ride must be accepted before it can start");
        }
        if (!ride.getStartOtp().equals(otp)) throw new BusinessException("Invalid ride start OTP");
        ride.setStatus(RideStatus.STARTED);
        ride.setStartedAt(Instant.now());
        ride.setRiderBoardedAt(ride.getStartedAt());
        Ride saved = rides.save(ride);
        notifications.create(ride.getRider().getUser(), "PUSH", "Ride started", "Your SheGo ride has started.");
        return saved;
    }

    @Transactional
    public Ride complete(UUID rideId) {
        Ride ride = rides.findById(rideId).orElseThrow();
        if (ride.getStatus() != RideStatus.STARTED) {
            throw new BusinessException("Only started rides can be completed");
        }
        ride.setStatus(RideStatus.COMPLETED);
        ride.setFinalFare(ride.getEstimatedFare());
        ride.setCompletedAt(Instant.now());
        ride.setRideCompletedAt(ride.getCompletedAt());
        if (ride.getDriver() != null) {
            DriverProfile driver = ride.getDriver();
            driver.setAvailable(true);
            driver.setCompletedRides(driver.getCompletedRides() + 1);
            drivers.save(driver);
            DriverEarning earning = new DriverEarning();
            earning.setDriver(driver);
            earning.setRide(ride);
            earning.setGrossFare(ride.getEstimatedFare());
            BigDecimal commission = ride.getEstimatedFare().multiply(BigDecimal.valueOf(0.15)).setScale(2, RoundingMode.HALF_UP);
            earning.setPlatformCommission(commission);
            earning.setNetEarning(ride.getEstimatedFare().subtract(commission));
            earnings.save(earning);
            safetyScoreService.recalculate(driver);
        }
        Ride saved = rides.save(ride);
        notifications.create(ride.getRider().getUser(), "PUSH", "Ride completed", "Your SheGo ride is complete.");
        return saved;
    }

    @Transactional
    public Ride cancel(UUID rideId) {
        Ride ride = rides.findById(rideId).orElseThrow();
        if (ride.getStatus() == RideStatus.COMPLETED) {
            throw new BusinessException("Completed ride cannot be cancelled");
        }
        ride.setStatus(RideStatus.CANCELLED);
        ride.setCancelledAt(Instant.now());
        if (ride.getDriver() != null) {
            DriverProfile driver = ride.getDriver();
            driver.setAvailable(true);
            drivers.save(driver);
        }
        return rides.save(ride);
    }

    public Ride get(UUID id) {
        return rides.findById(id).orElseThrow();
    }

    public List<Ride> history(User user) {
        RiderProfile rider = riders.findByUser(user).orElseThrow(() -> new BusinessException("Rider profile not found"));
        return rides.findByRiderOrderByCreatedAtDesc(rider);
    }

    public List<Ride> active() {
        return rides.findByStatusIn(ACTIVE);
    }

    private boolean isLateNight() {
        LocalTime now = LocalTime.now(ZoneId.of("Asia/Kolkata"));
        return !now.isBefore(LocalTime.of(22, 0)) || now.isBefore(LocalTime.of(5, 0));
    }

    private double distanceKm(double lat1, double lon1, double lat2, double lon2) {
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLon / 2) * Math.sin(dLon / 2);
        return BigDecimal.valueOf(6371 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))).setScale(2, RoundingMode.HALF_UP).doubleValue();
    }
}
