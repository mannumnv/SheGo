package com.shego.payment;

import com.shego.common.ApiResponse;
import com.shego.common.PaymentStatus;
import com.shego.ride.RideRepository;
import com.shego.user.CurrentUserService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
public class PaymentController {
    private final PaymentRepository payments;
    private final RideRepository rides;
    private final CurrentUserService currentUserService;

    public PaymentController(PaymentRepository payments, RideRepository rides, CurrentUserService currentUserService) {
        this.payments = payments;
        this.rides = rides;
        this.currentUserService = currentUserService;
    }

    @PostMapping("/api/payments/initiate")
    ApiResponse<Payment> initiate(@RequestBody PaymentDtos.InitiateRequest request) {
        Payment payment = new Payment();
        payment.setPayer(currentUserService.current());
        payment.setRide(request.rideId() == null ? null : rides.findById(request.rideId()).orElseThrow());
        payment.setAmount(request.amount());
        payment.setMethod(request.method());
        return ApiResponse.ok("Payment initiated", payments.save(payment));
    }

    @PostMapping("/api/payments/confirm")
    ApiResponse<Payment> confirm(@RequestBody PaymentDtos.ConfirmRequest request) {
        Payment payment = payments.findById(request.paymentId()).orElseThrow();
        payment.setStatus(PaymentStatus.CONFIRMED);
        payment.setProviderReference(request.providerReference());
        return ApiResponse.ok("Payment confirmed", payments.save(payment));
    }

    @GetMapping("/api/payments/history")
    ApiResponse<List<Payment>> history() {
        return ApiResponse.ok("Payment history", payments.findByPayerOrderByCreatedAtDesc(currentUserService.current()));
    }

    @PostMapping("/api/payments/refund")
    ApiResponse<Payment> refund(@RequestBody PaymentDtos.RefundRequest request) {
        Payment payment = payments.findById(request.paymentId()).orElseThrow();
        payment.setStatus(PaymentStatus.REFUNDED);
        payment.setProviderReference((payment.getProviderReference() == null ? "" : payment.getProviderReference()) + " REFUND:" + request.reason());
        return ApiResponse.ok("Payment refunded", payments.save(payment));
    }
}
