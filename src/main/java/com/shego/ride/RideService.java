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
import com.shego.storage.StorageService;
import com.shego.user.User;
import com.shego.vehicle.Vehicle;
import com.shego.vehicle.VehicleRepository;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalTime;
import java.time.ZoneId;
import java.util.List;
import java.util.UUID;

@Service
public class RideService {
    private static final List<RideStatus> ACTIVE = List.of(RideStatus.REQUESTED, RideStatus.ACCEPTED, RideStatus.DRIVER_REACHED, RideStatus.DRIVER_ARRIVING, RideStatus.STARTED);
    private static final int START_OTP_MAX_RETRIES = 5;
    private static final Duration START_OTP_TTL = Duration.ofMinutes(10);
    private final RideRepository rides;
    private final RiderProfileRepository riders;
    private final DriverProfileRepository drivers;
    private final SafetyScoreService safetyScoreService;
    private final DriverEarningRepository earnings;
    private final NotificationService notifications;
    private final VehicleRepository vehicles;
    private final PasswordEncoder passwordEncoder;
    private final StringRedisTemplate redis;
    private final StorageService storage;
    private final SecureRandom random = new SecureRandom();

    public RideService(RideRepository rides, RiderProfileRepository riders, DriverProfileRepository drivers,
                       SafetyScoreService safetyScoreService, DriverEarningRepository earnings,
                       NotificationService notifications, VehicleRepository vehicles, PasswordEncoder passwordEncoder,
                       StringRedisTemplate redis, StorageService storage) {
        this.rides = rides;
        this.riders = riders;
        this.drivers = drivers;
        this.safetyScoreService = safetyScoreService;
        this.earnings = earnings;
        this.notifications = notifications;
        this.vehicles = vehicles;
        this.passwordEncoder = passwordEncoder;
        this.redis = redis;
        this.storage = storage;
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
        ride.setLateNight(isLateNight());
        ride.setGuardianModeEnabled(ride.isLateNight());
        Ride saved = rides.save(ride);
        notifications.create(user, "PUSH", "Ride requested", "Your SheGo ride request has been created.");
        return saved;
    }

    @Transactional
    public Ride arrive(User user, UUID rideId) {
        Ride ride = assignedRideForDriver(user, rideId);
        if (ride.getStatus() != RideStatus.ACCEPTED && ride.getStatus() != RideStatus.DRIVER_ARRIVING) {
            throw new BusinessException("Ride must be accepted before marking arrival");
        }
        String otp = String.valueOf(1000 + random.nextInt(9000));
        ride.setStatus(RideStatus.DRIVER_REACHED);
        ride.setDriverReachedAt(Instant.now());
        ride.setStartOtpHash(passwordEncoder.encode(otp));
        ride.setStartOtpExpiresAt(ride.getDriverReachedAt().plus(START_OTP_TTL));
        ride.setStartOtpRetryCount(0);
        redis.opsForValue().set(startOtpKey(ride.getId()), otp, START_OTP_TTL);
        Ride saved = rides.save(ride);
        notifications.create(ride.getRider().getUser(), "PUSH", "Driver reached pickup", "Your ride start OTP is now available in the SheGo app.");
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

    public RideDtos.RideStartResponse start(User user, UUID rideId, String otp) {
        Ride ride = assignedRideForDriver(user, rideId);
        if (ride.getStatus() != RideStatus.DRIVER_REACHED) {
            throw new BusinessException("Driver must mark arrival before ride can start");
        }
        if (ride.getStartOtpExpiresAt() == null || ride.getStartOtpExpiresAt().isBefore(Instant.now())) {
            throw new BusinessException("Ride start OTP has expired. Mark arrival again to generate a new OTP.");
        }
        if (ride.getStartOtpRetryCount() >= START_OTP_MAX_RETRIES) {
            throw new BusinessException("Ride start OTP retry limit exceeded.");
        }
        if (otp == null || !passwordEncoder.matches(otp, ride.getStartOtpHash())) {
            ride.setStartOtpRetryCount(ride.getStartOtpRetryCount() + 1);
            rides.save(ride);
            throw new BusinessException("Invalid ride start OTP");
        }
        ride.setStatus(RideStatus.STARTED);
        ride.setStartedAt(Instant.now());
        ride.setRiderBoardedAt(ride.getStartedAt());
        Ride saved = rides.save(ride);
        redis.delete(startOtpKey(ride.getId()));
        notifications.create(ride.getRider().getUser(), "PUSH", "Ride started", "Your SheGo ride has started.");
        return new RideDtos.RideStartResponse(saved.getId(), saved.getStatus(), saved.getStartedAt());
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

    public RideDtos.RideDetailsResponse details(User user, UUID id) {
        Ride ride = get(id);
        boolean rider = ride.getRider().getUser().getId().equals(user.getId());
        boolean driver = ride.getDriver() != null && ride.getDriver().getUser().getId().equals(user.getId());
        if (!rider && !driver && user.getAuthorities().stream().noneMatch(a -> a.getAuthority().equals("ROLE_ADMIN") || a.getAuthority().equals("ROLE_SUPPORT"))) {
            throw new BusinessException("Ride not found for current user");
        }
        return details(ride, rider, driver);
    }

    public RideDtos.RideAcceptedResponse acceptedResponse(Ride ride) {
        return new RideDtos.RideAcceptedResponse(ride.getId(), ride.getStatus(), details(ride, true, false), details(ride, false, true));
    }

    public List<Ride> history(User user) {
        RiderProfile rider = riders.findByUser(user).orElseThrow(() -> new BusinessException("Rider profile not found"));
        return rides.findByRiderOrderByCreatedAtDesc(rider);
    }

    public List<Ride> active() {
        return rides.findByStatusIn(ACTIVE);
    }

    private Ride assignedRideForDriver(User user, UUID rideId) {
        DriverProfile driver = drivers.findByUser(user).orElseThrow(() -> new BusinessException("Driver profile not found"));
        Ride ride = rides.findById(rideId).orElseThrow();
        if (ride.getDriver() == null || !ride.getDriver().getId().equals(driver.getId())) {
            throw new BusinessException("Only assigned driver can update this ride");
        }
        return ride;
    }

    private RideDtos.RideDetailsResponse details(Ride ride, boolean forRider, boolean forDriver) {
        DriverProfile driver = ride.getDriver();
        Vehicle vehicle = ride.getVehicle();
        RiderProfile rider = ride.getRider();
        RideDtos.ParticipantDriverDetails driverDetails = driver == null ? null : new RideDtos.ParticipantDriverDetails(
                driver.getUser().getFullName(),
                driver.getUser().getMobileNumber(),
                temporaryUrl(driver.getProfilePhotoStorageKey()),
                vehicle == null ? ride.getVehicleType() : vehicle.getVehicleType(),
                ride.getVehicleRegistrationSnapshot(),
                ride.getVehicleModelSnapshot()
        );
        RideDtos.ParticipantRiderDetails riderDetails = forDriver ? new RideDtos.ParticipantRiderDetails(
                rider.getUser().getFullName(),
                rider.getUser().getMobileNumber(),
                temporaryUrl(rider.getProfilePhotoStorageKey())
        ) : null;
        String otp = forRider && ride.getStatus() == RideStatus.DRIVER_REACHED ? redis.opsForValue().get(startOtpKey(ride.getId())) : null;
        return new RideDtos.RideDetailsResponse(ride.getId(), ride.getStatus(), ride.getVehicleType(), rider.getId(),
                driver == null ? null : driver.getId(), vehicle == null ? null : vehicle.getId(),
                forRider ? driverDetails : null, riderDetails, ride.getPickupAddress(), ride.getDropAddress(),
                ride.getPickupLat(), ride.getPickupLng(), ride.getDropLat(), ride.getDropLng(), ride.getEtaMinutes(),
                ride.isGuardianModeEnabled(), ride.isLateNight(), otp, ride.getStartOtpExpiresAt(),
                ride.getAcceptedAt(), ride.getDriverReachedAt(), ride.getStartedAt());
    }

    private String temporaryUrl(String key) {
        if (key == null || key.isBlank()) {
            return null;
        }
        return storage.temporaryDownloadUrl(key);
    }

    private String startOtpKey(UUID rideId) {
        return "ride:start-otp:" + rideId;
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
