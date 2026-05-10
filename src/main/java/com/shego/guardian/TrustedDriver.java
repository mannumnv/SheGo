package com.shego.guardian;

import com.shego.common.BaseEntity;
import com.shego.driver.DriverProfile;
import com.shego.rider.RiderProfile;
import jakarta.persistence.Entity;
import jakarta.persistence.ManyToOne;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@Entity
public class TrustedDriver extends BaseEntity {
    @ManyToOne(optional = false)
    private RiderProfile rider;

    @ManyToOne(optional = false)
    private DriverProfile driver;
}
