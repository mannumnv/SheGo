package com.shego.vehicle;

import com.shego.driver.DriverProfile;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface VehicleRepository extends JpaRepository<Vehicle, UUID> {
    Optional<Vehicle> findByDriver(DriverProfile driver);
    Optional<Vehicle> findByDriverAndActiveTrue(DriverProfile driver);
}
