package com.shego.location;

import com.shego.ride.RideRepository;
import com.shego.user.UserRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
public class LocationService {
    private final RideLocationRepository locations;
    private final RideRepository rides;
    private final UserRepository users;

    public LocationService(RideLocationRepository locations, RideRepository rides, UserRepository users) {
        this.locations = locations;
        this.rides = rides;
        this.users = users;
    }

    public RideLocation save(LocationDtos.LiveLocationMessage message) {
        RideLocation location = new RideLocation();
        location.setRide(rides.findById(message.rideId()).orElseThrow());
        location.setUser(users.findById(message.userId()).orElseThrow());
        location.setLatitude(message.latitude());
        location.setLongitude(message.longitude());
        location.setSpeedKmph(message.speedKmph());
        location.setBearing(message.bearing());
        return locations.save(location);
    }

    public List<RideLocation> history(UUID rideId) {
        return locations.findByRideOrderByCreatedAtAsc(rides.findById(rideId).orElseThrow());
    }
}
