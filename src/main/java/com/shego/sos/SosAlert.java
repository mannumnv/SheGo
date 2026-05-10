package com.shego.sos;

import com.shego.common.BaseEntity;
import com.shego.common.SosStatus;
import com.shego.ride.Ride;
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
public class SosAlert extends BaseEntity {
    @ManyToOne(optional = false)
    private User triggeredBy;

    @ManyToOne
    private Ride ride;

    private double latitude;
    private double longitude;
    private String message;

    @Enumerated(EnumType.STRING)
    private SosStatus status = SosStatus.ACTIVE;

    private Instant resolvedAt;
    private String resolutionNotes;
}
