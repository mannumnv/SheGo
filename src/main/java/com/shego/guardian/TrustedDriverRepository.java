package com.shego.guardian;

import com.shego.driver.DriverProfile;
import com.shego.rider.RiderProfile;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface TrustedDriverRepository extends JpaRepository<TrustedDriver, UUID> {
    List<TrustedDriver> findByRider(RiderProfile rider);
    boolean existsByRiderAndDriver(RiderProfile rider, DriverProfile driver);
}
