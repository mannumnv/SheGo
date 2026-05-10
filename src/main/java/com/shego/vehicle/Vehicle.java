package com.shego.vehicle;

import com.shego.common.BaseEntity;
import com.shego.common.VehicleType;
import com.shego.driver.DriverProfile;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.OneToOne;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@Entity
public class Vehicle extends BaseEntity {
    @OneToOne(optional = false)
    private DriverProfile driver;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private VehicleType vehicleType;

    @Column(nullable = false, unique = true)
    private String registrationNumber;

    private String insurancePolicyNumber;
    private String model;
    private boolean active = true;
}
