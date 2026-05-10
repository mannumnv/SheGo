package com.shego.commute;

import com.shego.common.BaseEntity;
import com.shego.common.CommuteFrequency;
import com.shego.common.CommuteStatus;
import com.shego.common.CommuteType;
import com.shego.common.VehicleType;
import com.shego.driver.DriverProfile;
import com.shego.rider.RiderProfile;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.ManyToOne;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDate;
import java.time.LocalTime;

@Getter
@Setter
@NoArgsConstructor
@Entity
public class CommuteSchedule extends BaseEntity {
    @ManyToOne(optional = false)
    private RiderProfile rider;

    @ManyToOne
    private DriverProfile preferredDriver;

    @Enumerated(EnumType.STRING)
    private CommuteType commuteType;

    @Enumerated(EnumType.STRING)
    private CommuteFrequency frequency;

    @Enumerated(EnumType.STRING)
    private VehicleType vehicleType;

    @Enumerated(EnumType.STRING)
    private CommuteStatus status = CommuteStatus.ACTIVE;

    private String pickupAddress;
    private String dropAddress;
    private double pickupLat;
    private double pickupLng;
    private double dropLat;
    private double dropLng;
    private LocalTime pickupTime;
    private LocalDate startDate;
    private LocalDate endDate;
    private String daysOfWeek;
    private boolean active = true;
}
