package com.shego.rating;

import com.shego.common.ApiResponse;
import com.shego.ride.RideRepository;
import com.shego.user.CurrentUserService;
import com.shego.user.UserRepository;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
public class RatingController {
    private final RatingRepository ratings;
    private final RideRepository rides;
    private final UserRepository users;
    private final CurrentUserService currentUserService;

    public RatingController(RatingRepository ratings, RideRepository rides, UserRepository users, CurrentUserService currentUserService) {
        this.ratings = ratings;
        this.rides = rides;
        this.users = users;
        this.currentUserService = currentUserService;
    }

    @PostMapping("/api/ratings")
    ApiResponse<Rating> create(@RequestBody RatingDtos.RatingRequest request) {
        Rating rating = new Rating();
        rating.setRide(rides.findById(request.rideId()).orElseThrow());
        rating.setRatedBy(currentUserService.current());
        rating.setRatedUser(users.findById(request.ratedUserId()).orElseThrow());
        rating.setOverallRating(request.overallRating());
        rating.setSafetyRating(request.safetyRating());
        rating.setComfortRating(request.comfortRating());
        rating.setDrivingBehaviorRating(request.drivingBehaviorRating());
        rating.setComments(request.comments());
        rating.setUnsafeReported(request.unsafeReported());
        return ApiResponse.ok("Rating submitted", ratings.save(rating));
    }

    @GetMapping("/api/drivers/{id}/ratings")
    ApiResponse<List<Rating>> driverRatings(@PathVariable UUID id) {
        return ApiResponse.ok("Driver ratings", ratings.findByRatedUser(users.findById(id).orElseThrow()));
    }
}
