package com.shego.safety;

import com.shego.common.KycStatus;
import com.shego.driver.DriverProfile;
import com.shego.driver.DriverProfileRepository;
import com.shego.exception.BusinessException;
import com.shego.ride.RideRepository;
import com.shego.user.User;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class SafetyScoreService {
    private final SafetyScoreRepository scores;
    private final SafetyEventRepository events;
    private final DriverProfileRepository drivers;
    private final RideRepository rides;

    public SafetyScoreService(SafetyScoreRepository scores, SafetyEventRepository events, DriverProfileRepository drivers, RideRepository rides) {
        this.scores = scores;
        this.events = events;
        this.drivers = drivers;
        this.rides = rides;
    }

    public SafetyScore get(UUID driverId) {
        DriverProfile driver = drivers.findById(driverId)
                .orElseThrow(() -> new BusinessException("Driver not found", HttpStatus.NOT_FOUND));
        return scores.findByDriver(driver).orElseGet(() -> recalculate(driver));
    }

    public SafetyEvent event(User actor, SafetyDtos.EventRequest request) {
        SafetyEvent event = new SafetyEvent();
        event.setActor(actor);
        event.setRide(request.rideId() == null ? null : rides.findById(request.rideId())
                .orElseThrow(() -> new BusinessException("Ride not found", HttpStatus.NOT_FOUND)));
        event.setEventType(request.eventType());
        event.setSeverity(request.severity());
        event.setDetails(request.details());
        return events.save(event);
    }

    public SafetyScore recalculate(DriverProfile driver) {
        SafetyScore score = scores.findByDriver(driver).orElseGet(SafetyScore::new);
        score.setDriver(driver);
        int value = 50;
        if (driver.getKycStatus() == KycStatus.APPROVED) value += 20;
        if (driver.isBackgroundVerified()) value += 10;
        value += Math.min(10, driver.getCompletedRides() / 10);
        value += Math.min(10, (int) Math.round(driver.getAverageRating() * 2));
        value -= score.getComplaintCount() * 5;
        value -= score.getRouteDeviationCount() * 3;
        value -= score.getEmergencyIncidentCount() * 15;
        value = Math.max(0, Math.min(100, value));
        score.setScore(value);
        score.setExplanation("Based on KYC, background verification, rating, completion history, complaints, deviations, and SOS incidents.");
        return scores.save(score);
    }

    public java.util.List<SafetyEvent> allEvents() {
        return events.findAll();
    }
}
