package com.shego.rating;

import com.shego.exception.BusinessException;
import com.shego.ride.RideRepository;
import com.shego.user.CurrentUserService;
import com.shego.user.User;
import com.shego.user.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static com.shego.testsupport.TestDoubles.proxy;

class RatingControllerTest {
    @Test
    void createReturnsNotFoundWhenRideIsWrong() {
        UUID rideId = UUID.randomUUID();
        RatingRepository ratings = proxy(RatingRepository.class, java.util.Map.of());
        RideRepository rides = proxy(RideRepository.class, java.util.Map.of("findById", Optional.empty()));
        UserRepository users = proxy(UserRepository.class, java.util.Map.of());
        CurrentUserService currentUserService = new CurrentUserService();

        RatingController controller = new RatingController(ratings, rides, users, currentUserService);

        assertThatThrownBy(() -> controller.create(new RatingDtos.RatingRequest(rideId, UUID.randomUUID(), 5, 5, 5, 5, "good", false)))
                .isInstanceOfSatisfying(BusinessException.class, exception -> {
                    assertThat(exception.getMessage()).isEqualTo("Ride not found");
                    assertThat(exception.status()).isEqualTo(HttpStatus.NOT_FOUND);
                });
    }
}
