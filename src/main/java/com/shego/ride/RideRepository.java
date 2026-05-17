package com.shego.ride;

import com.shego.common.RideStatus;
import com.shego.driver.DriverProfile;
import com.shego.rider.RiderProfile;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface RideRepository extends JpaRepository<Ride, UUID> {
    List<Ride> findByRiderOrderByCreatedAtDesc(RiderProfile rider);
    List<Ride> findByDriverAndStatusIn(DriverProfile driver, List<RideStatus> statuses);
    List<Ride> findByStatusIn(List<RideStatus> statuses);
    List<Ride> findByStatusOrderByCreatedAtDesc(RideStatus status);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select r from Ride r where r.id = :id")
    Optional<Ride> findByIdForUpdate(UUID id);
}
