package com.shego.subscription;

import com.shego.common.BaseEntity;
import com.shego.common.SubscriptionStatus;
import com.shego.user.User;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.ManyToOne;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;

@Getter
@Setter
@NoArgsConstructor
@Entity
public class UserSubscription extends BaseEntity {
    @ManyToOne(optional = false)
    private User user;

    @ManyToOne(optional = false)
    private SubscriptionPlan plan;

    @Enumerated(EnumType.STRING)
    private SubscriptionStatus status = SubscriptionStatus.ACTIVE;

    private Instant startsAt;
    private Instant endsAt;
}
