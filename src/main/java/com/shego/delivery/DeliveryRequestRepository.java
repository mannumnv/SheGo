package com.shego.delivery;

import com.shego.rider.RiderProfile;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface DeliveryRequestRepository extends JpaRepository<DeliveryRequest, UUID> {
    List<DeliveryRequest> findByRequestedByOrderByCreatedAtDesc(RiderProfile rider);
}
