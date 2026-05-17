package com.shego.location;

import com.shego.ride.Ride;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface RideRouteSnapshotRepository extends JpaRepository<RideRouteSnapshot, UUID> {
    Optional<RideRouteSnapshot> findByRide(Ride ride);
}
