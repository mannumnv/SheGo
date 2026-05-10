package com.shego.rating;

import java.util.UUID;

public class RatingDtos {
    public record RatingRequest(UUID rideId, UUID ratedUserId, int overallRating, int safetyRating,
                                int comfortRating, int drivingBehaviorRating, String comments, boolean unsafeReported) {
    }
}
