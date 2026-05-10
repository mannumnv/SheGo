package com.shego.payment;

import com.shego.common.BaseEntity;
import com.shego.driver.DriverProfile;
import com.shego.ride.Ride;
import jakarta.persistence.Entity;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToOne;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;

@Getter
@Setter
@NoArgsConstructor
@Entity
public class DriverEarning extends BaseEntity {
    @ManyToOne(optional = false)
    private DriverProfile driver;

    @OneToOne(optional = false)
    private Ride ride;

    private BigDecimal grossFare;
    private BigDecimal platformCommission;
    private BigDecimal netEarning;
}
