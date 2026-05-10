package com.shego.guardian;

import com.shego.common.BaseEntity;
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
public class GuardianContact extends BaseEntity {
    @ManyToOne(optional = false)
    private RiderProfile rider;

    private String name;
    private String mobileNumber;
    private String relationship;
    private boolean autoShareLateNight;
}
