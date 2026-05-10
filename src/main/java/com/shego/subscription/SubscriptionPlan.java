package com.shego.subscription;

import com.shego.common.BaseEntity;
import jakarta.persistence.Entity;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;

@Getter
@Setter
@NoArgsConstructor
@Entity
public class SubscriptionPlan extends BaseEntity {
    private String name;
    private String description;
    private BigDecimal monthlyPrice;
    private boolean active;
}
