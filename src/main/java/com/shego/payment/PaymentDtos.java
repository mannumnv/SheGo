package com.shego.payment;

import com.shego.common.PaymentMethod;

import java.math.BigDecimal;
import java.util.UUID;

public class PaymentDtos {
    public record InitiateRequest(UUID rideId, BigDecimal amount, PaymentMethod method) {
    }

    public record ConfirmRequest(UUID paymentId, String providerReference) {
    }

    public record RefundRequest(UUID paymentId, String reason) {
    }
}
