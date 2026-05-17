package com.shego.guardian;

import com.shego.exception.BusinessException;
import com.shego.driver.DriverProfile;
import com.shego.driver.DriverProfileRepository;
import com.shego.rider.RiderProfile;
import com.shego.rider.RiderProfileRepository;
import com.shego.ride.Ride;
import com.shego.ride.RideRepository;
import com.shego.user.User;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
public class GuardianService {
    private final GuardianContactRepository contacts;
    private final TrustedDriverRepository trustedDrivers;
    private final RiderProfileRepository riders;
    private final DriverProfileRepository drivers;
    private final RideRepository rides;

    public GuardianService(GuardianContactRepository contacts, TrustedDriverRepository trustedDrivers,
                           RiderProfileRepository riders, DriverProfileRepository drivers, RideRepository rides) {
        this.contacts = contacts;
        this.trustedDrivers = trustedDrivers;
        this.riders = riders;
        this.drivers = drivers;
        this.rides = rides;
    }

    public GuardianContact add(User user, GuardianDtos.UpsertRequest request) {
        RiderProfile rider = riders.findByUser(user)
                .orElseThrow(() -> new BusinessException("Rider profile not found", HttpStatus.FORBIDDEN));
        GuardianContact contact = new GuardianContact();
        contact.setRider(rider);
        contact.setName(request.name());
        contact.setMobileNumber(request.mobileNumber());
        contact.setRelationship(request.relationship());
        contact.setAutoShareLateNight(request.autoShareLateNight());
        return contacts.save(contact);
    }

    public List<GuardianContact> list(User user) {
        RiderProfile rider = riders.findByUser(user)
                .orElseThrow(() -> new BusinessException("Rider profile not found", HttpStatus.FORBIDDEN));
        return contacts.findByRider(rider);
    }

    public void delete(UUID id) {
        contacts.deleteById(id);
    }

    public Ride share(UUID rideId) {
        Ride ride = rides.findById(rideId)
                .orElseThrow(() -> new BusinessException("Ride not found", HttpStatus.NOT_FOUND));
        ride.setGuardianModeEnabled(true);
        return rides.save(ride);
    }

    public TrustedDriver addTrustedDriver(User user, UUID driverId) {
        RiderProfile rider = riders.findByUser(user)
                .orElseThrow(() -> new BusinessException("Rider profile not found", HttpStatus.FORBIDDEN));
        DriverProfile driver = drivers.findById(driverId)
                .orElseThrow(() -> new BusinessException("Driver not found", HttpStatus.NOT_FOUND));
        if (trustedDrivers.existsByRiderAndDriver(rider, driver)) {
            throw new BusinessException("Driver is already in trusted circle");
        }
        TrustedDriver trustedDriver = new TrustedDriver();
        trustedDriver.setRider(rider);
        trustedDriver.setDriver(driver);
        return trustedDrivers.save(trustedDriver);
    }

    public List<TrustedDriver> trustedDrivers(User user) {
        RiderProfile rider = riders.findByUser(user)
                .orElseThrow(() -> new BusinessException("Rider profile not found", HttpStatus.FORBIDDEN));
        return trustedDrivers.findByRider(rider);
    }
}
