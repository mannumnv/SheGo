package com.shego.payment;

import com.shego.common.BaseEntity;
import com.shego.common.PaymentMethod;
import com.shego.common.PaymentStatus;
import com.shego.ride.Ride;
import com.shego.user.User;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.ManyToOne;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;

@Getter
@Setter
@NoArgsConstructor
@Entity
public class Payment extends BaseEntity {
    @ManyToOne(optional = false)
    private User payer;

    @ManyToOne
    private Ride ride;

    private BigDecimal amount;

    @Enumerated(EnumType.STRING)
    private PaymentMethod method;

    @Enumerated(EnumType.STRING)
    private PaymentStatus status = PaymentStatus.INITIATED;

    private String providerReference;
}
