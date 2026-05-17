package com.shego.location;

import com.shego.exception.BusinessException;
import com.shego.ride.RideRepository;
import com.shego.user.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static com.shego.testsupport.TestDoubles.proxy;

class LocationServiceTest {
    @Test
    void historyReturnsNotFoundWhenRideDoesNotExist() {
        UUID rideId = UUID.randomUUID();
        RideLocationRepository locations = proxy(RideLocationRepository.class, java.util.Map.of());
        RideRepository rides = proxy(RideRepository.class, java.util.Map.of("findById", Optional.empty()));

        LocationService service = new LocationService(
                locations,
                rides,
                proxy(UserRepository.class, java.util.Map.of()),
                proxy(SavedLocationRepository.class, java.util.Map.of()),
                proxy(RecentLocationSearchRepository.class, java.util.Map.of()),
                proxy(RideRouteSnapshotRepository.class, java.util.Map.of()),
                request -> new LocationDtos.DirectionsResponse("LOCAL_MOCK", 0, 0, "", java.util.List.of(), null),
                new org.springframework.data.redis.core.StringRedisTemplate()
        );

        assertThatThrownBy(() -> service.history(rideId))
                .isInstanceOfSatisfying(BusinessException.class, exception -> {
                    assertThat(exception.getMessage()).isEqualTo("Ride not found");
                    assertThat(exception.status()).isEqualTo(HttpStatus.NOT_FOUND);
                });
    }
}
