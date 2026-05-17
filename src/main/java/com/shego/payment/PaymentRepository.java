package com.shego.payment;

import com.shego.user.User;
import com.shego.ride.Ride;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface PaymentRepository extends JpaRepository<Payment, UUID> {
    List<Payment> findByPayerOrderByCreatedAtDesc(User payer);
    Optional<Payment> findFirstByRideOrderByCreatedAtDesc(Ride ride);
}
