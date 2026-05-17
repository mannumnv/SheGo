package com.shego.safety;

import com.shego.driver.DriverProfileRepository;
import com.shego.exception.BusinessException;
import com.shego.ride.RideRepository;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static com.shego.testsupport.TestDoubles.proxy;

class SafetyScoreServiceTest {
    @Test
    void getReturnsNotFoundWhenDriverDoesNotExist() {
        UUID driverId = UUID.randomUUID();
        DriverProfileRepository drivers = proxy(DriverProfileRepository.class, java.util.Map.of("findById", Optional.empty()));

        SafetyScoreService service = new SafetyScoreService(
                proxy(SafetyScoreRepository.class, java.util.Map.of()),
                proxy(SafetyEventRepository.class, java.util.Map.of()),
                drivers,
                proxy(RideRepository.class, java.util.Map.of())
        );

        assertThatThrownBy(() -> service.get(driverId))
                .isInstanceOfSatisfying(BusinessException.class, exception -> {
                    assertThat(exception.getMessage()).isEqualTo("Driver not found");
                    assertThat(exception.status()).isEqualTo(HttpStatus.NOT_FOUND);
                });
    }
}
