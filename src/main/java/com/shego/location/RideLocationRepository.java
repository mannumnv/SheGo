package com.shego.location;

import com.shego.ride.Ride;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface RideLocationRepository extends JpaRepository<RideLocation, UUID> {
    List<RideLocation> findByRideOrderByCreatedAtAsc(Ride ride);
}
