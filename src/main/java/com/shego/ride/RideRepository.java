package com.shego.ride;

import com.shego.common.RideStatus;
import com.shego.driver.DriverProfile;
import com.shego.rider.RiderProfile;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface RideRepository extends JpaRepository<Ride, UUID> {
    List<Ride> findByRiderOrderByCreatedAtDesc(RiderProfile rider);
    List<Ride> findByDriverAndStatusIn(DriverProfile driver, List<RideStatus> statuses);
    List<Ride> findByStatusIn(List<RideStatus> statuses);
}
