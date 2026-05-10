package com.shego.rider;

import com.shego.user.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface RiderProfileRepository extends JpaRepository<RiderProfile, UUID> {
    Optional<RiderProfile> findByUser(User user);
    List<RiderProfile> findByRiderAgeLessThan(int age);
    List<RiderProfile> findByVerificationTypeAndKycStatus(com.shego.common.VerificationType verificationType, com.shego.common.KycStatus kycStatus);
}
