package com.shego.payment;

import com.shego.driver.DriverProfile;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface DriverEarningRepository extends JpaRepository<DriverEarning, UUID> {
    List<DriverEarning> findByDriverOrderByCreatedAtDesc(DriverProfile driver);
}
