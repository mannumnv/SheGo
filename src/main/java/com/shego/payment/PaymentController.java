package com.shego.payment;

import com.shego.common.ApiResponse;
import com.shego.common.PaymentMethod;
import com.shego.common.PaymentStatus;
import com.shego.exception.BusinessException;
import com.shego.ride.Ride;
import com.shego.ride.RideRepository;
import com.shego.user.CurrentUserService;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@RestController
public class PaymentController {
    private static final Logger log = LoggerFactory.getLogger(PaymentController.class);
    private final PaymentRepository payments;
    private final RideRepository rides;
    private final CurrentUserService currentUserService;

    public PaymentController(PaymentRepository payments, RideRepository rides, CurrentUserService currentUserService) {
        this.payments = payments;
        this.rides = rides;
        this.currentUserService = currentUserService;
    }

    @PostMapping("/api/payments/initiate")
    ApiResponse<PaymentDtos.PaymentResponse> initiate(@RequestBody PaymentDtos.InitiateRequest request) {
        log.debug("POST /api/payments/initiate rideId={}, method={}", request.rideId(), request.method());
        Payment payment = new Payment();
        payment.setPayer(currentUserService.current());
        Ride ride = request.rideId() == null ? null : rides.findById(request.rideId())
                .orElseThrow(() -> new BusinessException("Ride not found", HttpStatus.NOT_FOUND));
        payment.setRide(ride);
        applyFareBreakdown(payment, ride, request.amount());
        payment.setMethod(request.method() == null ? PaymentMethod.CASH : request.method());
        payment.setStatus(payment.getMethod() == PaymentMethod.CASH ? PaymentStatus.PENDING : PaymentStatus.PROCESSING);
        payment.setInvoiceNumber("SHEGO-" + Instant.now().toEpochMilli());
        return ApiResponse.ok("Payment initiated", PaymentDtos.PaymentResponse.from(payments.save(payment)));
    }

    @PostMapping("/api/payments/confirm")
    ApiResponse<PaymentDtos.PaymentResponse> confirm(@RequestBody PaymentDtos.ConfirmRequest request) {
        log.debug("POST /api/payments/confirm paymentId={}", request.paymentId());
        Payment payment = payments.findById(request.paymentId())
                .orElseThrow(() -> new BusinessException("Payment not found", HttpStatus.NOT_FOUND));
        payment.setStatus(PaymentStatus.PAID);
        payment.setProviderReference(request.providerReference());
        return ApiResponse.ok("Payment confirmed", PaymentDtos.PaymentResponse.from(payments.save(payment)));
    }

    @GetMapping("/api/payments/history")
    ApiResponse<List<PaymentDtos.PaymentResponse>> history() {
        return ApiResponse.ok("Payment history", payments.findByPayerOrderByCreatedAtDesc(currentUserService.current()).stream()
                .map(PaymentDtos.PaymentResponse::from).toList());
    }

    @PostMapping("/api/payments/refund")
    ApiResponse<PaymentDtos.PaymentResponse> refund(@RequestBody PaymentDtos.RefundRequest request) {
        log.debug("POST /api/payments/refund paymentId={}", request.paymentId());
        Payment payment = payments.findById(request.paymentId())
                .orElseThrow(() -> new BusinessException("Payment not found", HttpStatus.NOT_FOUND));
        payment.setStatus(PaymentStatus.REFUNDED);
        payment.setProviderReference((payment.getProviderReference() == null ? "" : payment.getProviderReference()) + " REFUND:" + request.reason());
        return ApiResponse.ok("Payment refunded", PaymentDtos.PaymentResponse.from(payments.save(payment)));
    }

    @GetMapping("/api/payments/ride/{rideId}/invoice")
    ApiResponse<PaymentDtos.InvoiceResponse> invoice(@org.springframework.web.bind.annotation.PathVariable UUID rideId) {
        Ride ride = rides.findById(rideId)
                .orElseThrow(() -> new BusinessException("Ride not found", HttpStatus.NOT_FOUND));
        Payment payment = payments.findFirstByRideOrderByCreatedAtDesc(ride)
                .orElseThrow(() -> new BusinessException("Payment not found", HttpStatus.NOT_FOUND));
        String driverName = ride.getDriver() == null ? null : ride.getDriver().getUser().getFullName();
        return ApiResponse.ok("Invoice generated", new PaymentDtos.InvoiceResponse(payment.getId(), ride.getId(),
                payment.getInvoiceNumber(), Instant.now(), ride.getRider().getUser().getFullName(), driverName,
                payment.getAmount(), payment.getStatus(), "PDF generation adapter pending; use this response as MVP receipt."));
    }

    private void applyFareBreakdown(Payment payment, Ride ride, BigDecimal requestedAmount) {
        BigDecimal baseFare = BigDecimal.valueOf(25);
        BigDecimal distanceFare = ride == null ? BigDecimal.ZERO : BigDecimal.valueOf(ride.getDistanceKm()).multiply(BigDecimal.valueOf(12)).setScale(2, java.math.RoundingMode.HALF_UP);
        BigDecimal timeFare = ride == null ? BigDecimal.ZERO : BigDecimal.valueOf(Math.max(0, ride.getEtaMinutes() - 5)).multiply(BigDecimal.valueOf(1.5)).setScale(2, java.math.RoundingMode.HALF_UP);
        BigDecimal platformFee = BigDecimal.valueOf(5);
        BigDecimal surgeFee = BigDecimal.ZERO;
        BigDecimal amount = requestedAmount != null && requestedAmount.compareTo(BigDecimal.ZERO) > 0
                ? requestedAmount
                : baseFare.add(distanceFare).add(timeFare).add(platformFee).add(surgeFee);
        payment.setBaseFare(baseFare);
        payment.setDistanceFare(distanceFare);
        payment.setTimeFare(timeFare);
        payment.setPlatformFee(platformFee);
        payment.setSurgeFee(surgeFee);
        payment.setAmount(amount);
    }
}
