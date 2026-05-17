package com.shego.sos;

import com.shego.common.SosStatus;
import com.shego.exception.BusinessException;
import com.shego.ride.RideRepository;
import com.shego.user.User;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Service
public class SosService {
    private final SosAlertRepository alerts;
    private final RideRepository rides;

    public SosService(SosAlertRepository alerts, RideRepository rides) {
        this.alerts = alerts;
        this.rides = rides;
    }

    public SosAlert trigger(User user, SosDtos.TriggerRequest request) {
        SosAlert alert = new SosAlert();
        alert.setTriggeredBy(user);
        alert.setRide(request.rideId() == null ? null : rides.findById(request.rideId())
                .orElseThrow(() -> new BusinessException("Ride not found", HttpStatus.NOT_FOUND)));
        alert.setLatitude(request.latitude());
        alert.setLongitude(request.longitude());
        alert.setMessage(request.message());
        return alerts.save(alert);
    }

    public SosAlert resolve(UUID id, String notes) {
        SosAlert alert = alerts.findById(id)
                .orElseThrow(() -> new BusinessException("SOS alert not found", HttpStatus.NOT_FOUND));
        alert.setStatus(SosStatus.RESOLVED);
        alert.setResolvedAt(Instant.now());
        alert.setResolutionNotes(notes);
        return alerts.save(alert);
    }

    public List<SosAlert> active() {
        return alerts.findByStatus(SosStatus.ACTIVE);
    }
}
