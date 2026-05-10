package com.shego.location;

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
public class RideLocation extends BaseEntity {
    @ManyToOne(optional = false)
    private Ride ride;

    @ManyToOne(optional = false)
    private User user;

    private double latitude;
    private double longitude;
    private double speedKmph;
    private double bearing;
}
