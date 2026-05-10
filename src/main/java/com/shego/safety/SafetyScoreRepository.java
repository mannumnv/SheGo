package com.shego.safety;

import com.shego.driver.DriverProfile;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface SafetyScoreRepository extends JpaRepository<SafetyScore, UUID> {
    Optional<SafetyScore> findByDriver(DriverProfile driver);
}
