package com.shego.guardian;

import com.shego.rider.RiderProfile;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface GuardianContactRepository extends JpaRepository<GuardianContact, UUID> {
    List<GuardianContact> findByRider(RiderProfile rider);
}
