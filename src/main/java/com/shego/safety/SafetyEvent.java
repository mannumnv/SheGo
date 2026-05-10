package com.shego.safety;

import com.shego.common.BaseEntity;
import com.shego.ride.Ride;
import com.shego.user.User;
import jakarta.persistence.Entity;
import jakarta.persistence.ManyToOne;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@Entity
public class SafetyEvent extends BaseEntity {
    @ManyToOne
    private Ride ride;

    @ManyToOne(optional = false)
    private User actor;

    private String eventType;
    private String severity;
    private String details;
}
