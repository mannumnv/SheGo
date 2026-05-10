package com.shego.childride;

import com.shego.rider.RiderProfile;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface ChildRideRepository extends JpaRepository<ChildRide, UUID> {
    List<ChildRide> findByGuardianOrderByCreatedAtDesc(RiderProfile guardian);
}
