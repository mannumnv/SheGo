package com.shego.rating;

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
public class Rating extends BaseEntity {
    @ManyToOne(optional = false)
    private Ride ride;

    @ManyToOne(optional = false)
    private User ratedBy;

    @ManyToOne(optional = false)
    private User ratedUser;

    private int overallRating;
    private int safetyRating;
    private int comfortRating;
    private int drivingBehaviorRating;
    private String comments;
    private boolean unsafeReported;
}
