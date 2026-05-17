package com.shego.location;

import com.shego.common.BaseEntity;
import com.shego.ride.Ride;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Lob;
import jakarta.persistence.OneToOne;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;

@Getter
@Setter
@NoArgsConstructor
@Entity
public class RideRouteSnapshot extends BaseEntity {
    @OneToOne(optional = false)
    private Ride ride;

    private String provider;
    private BigDecimal distanceKm;
    private Integer etaMinutes;

    @Column(name = "encoded_polyline", columnDefinition = "TEXT")
    private String encodedPolyline;

    @Lob
    @Column(columnDefinition = "text")
    private String routeMetadataJson;
}
