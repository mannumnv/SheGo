package com.shego.safety;

import com.shego.common.BaseEntity;
import com.shego.driver.DriverProfile;
import jakarta.persistence.Entity;
import jakarta.persistence.OneToOne;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@Entity
public class SafetyScore extends BaseEntity {
    @OneToOne(optional = false)
    private DriverProfile driver;

    private int score;
    private int routeDeviationCount;
    private int complaintCount;
    private int emergencyIncidentCount;
    private String explanation;
}
