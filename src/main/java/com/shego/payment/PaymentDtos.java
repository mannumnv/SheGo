package com.shego.payment;

import com.shego.common.PaymentMethod;
import com.shego.common.PaymentStatus;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

public class PaymentDtos {
    public record InitiateRequest(UUID rideId, BigDecimal amount, PaymentMethod method) {
    }

    public record ConfirmRequest(UUID paymentId, String providerReference) {
    }

    public record RefundRequest(UUID paymentId, String reason) {
    }

    public record FareBreakdown(BigDecimal baseFare, BigDecimal distanceFare, BigDecimal timeFare,
                                BigDecimal platformFee, BigDecimal surgeFee, BigDecimal totalFare) {
    }

    public record PaymentResponse(UUID paymentId, UUID rideId, BigDecimal amount, PaymentMethod method,
                                  PaymentStatus status, FareBreakdown fareBreakdown, String providerReference,
                                  String invoiceNumber) {
        static PaymentResponse from(Payment payment) {
            return new PaymentResponse(payment.getId(), payment.getRide() == null ? null : payment.getRide().getId(),
                    payment.getAmount(), payment.getMethod(), payment.getStatus(),
                    new FareBreakdown(payment.getBaseFare(), payment.getDistanceFare(), payment.getTimeFare(),
                            payment.getPlatformFee(), payment.getSurgeFee(), payment.getAmount()),
                    payment.getProviderReference(), payment.getInvoiceNumber());
        }
    }

    public record InvoiceResponse(UUID paymentId, UUID rideId, String invoiceNumber, Instant generatedAt,
                                  String riderName, String driverName, BigDecimal totalFare, PaymentStatus paymentStatus,
                                  String downloadStatus) {
    }
}
