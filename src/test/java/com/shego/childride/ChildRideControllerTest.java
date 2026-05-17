package com.shego.childride;

import com.shego.exception.BusinessException;
import com.shego.rider.RiderProfileRepository;
import com.shego.user.CurrentUserService;
import com.shego.user.User;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

import java.time.Instant;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static com.shego.testsupport.TestDoubles.authenticate;
import static com.shego.testsupport.TestDoubles.proxy;

class ChildRideControllerTest {
    @Test
    void bookReturnsForbiddenWhenCurrentUserIsNotRider() {
        User user = new User();
        authenticate(user);
        ChildRideRepository childRides = proxy(ChildRideRepository.class, java.util.Map.of());
        RiderProfileRepository riders = proxy(RiderProfileRepository.class, java.util.Map.of("findByUser", Optional.empty()));

        ChildRideController controller = new ChildRideController(childRides, riders, new CurrentUserService());

        assertThatThrownBy(() -> controller.book(new ChildRideDtos.BookRequest("Child", Instant.now())))
                .isInstanceOfSatisfying(BusinessException.class, exception -> {
                    assertThat(exception.getMessage()).isEqualTo("Rider profile not found");
                    assertThat(exception.status()).isEqualTo(HttpStatus.FORBIDDEN);
                });
    }
}
