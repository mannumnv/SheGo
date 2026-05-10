package com.shego.childride;

import com.shego.common.BaseEntity;
import com.shego.driver.DriverProfile;
import com.shego.rider.RiderProfile;
import jakarta.persistence.Entity;
import jakarta.persistence.ManyToOne;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;

@Getter
@Setter
@NoArgsConstructor
@Entity
public class ChildRide extends BaseEntity {
    @ManyToOne(optional = false)
    private RiderProfile guardian;

    @ManyToOne
    private DriverProfile driver;

    private String childName;
    private String pickupOtp;
    private String dropOtp;
    private String status;
    private Instant scheduledAt;
}
