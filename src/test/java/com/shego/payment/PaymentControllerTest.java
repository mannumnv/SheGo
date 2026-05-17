package com.shego.payment;

import com.shego.common.PaymentMethod;
import com.shego.exception.BusinessException;
import com.shego.ride.RideRepository;
import com.shego.user.CurrentUserService;
import com.shego.user.User;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static com.shego.testsupport.TestDoubles.authenticate;
import static com.shego.testsupport.TestDoubles.proxy;

class PaymentControllerTest {
    @Test
    void initiateReturnsNotFoundWhenRideIdIsWrong() {
        UUID rideId = UUID.randomUUID();
        authenticate(new User());
        PaymentRepository payments = proxy(PaymentRepository.class, java.util.Map.of());
        RideRepository rides = proxy(RideRepository.class, java.util.Map.of("findById", Optional.empty()));

        PaymentController controller = new PaymentController(payments, rides, new CurrentUserService());

        assertThatThrownBy(() -> controller.initiate(new PaymentDtos.InitiateRequest(rideId, BigDecimal.TEN, PaymentMethod.CASH)))
                .isInstanceOfSatisfying(BusinessException.class, exception -> {
                    assertThat(exception.getMessage()).isEqualTo("Ride not found");
                    assertThat(exception.status()).isEqualTo(HttpStatus.NOT_FOUND);
                });
    }

    @Test
    void confirmReturnsNotFoundWhenPaymentIdIsWrong() {
        UUID paymentId = UUID.randomUUID();
        PaymentRepository payments = proxy(PaymentRepository.class, java.util.Map.of("findById", Optional.empty()));

        PaymentController controller = new PaymentController(payments, proxy(RideRepository.class, java.util.Map.of()), new CurrentUserService());

        assertThatThrownBy(() -> controller.confirm(new PaymentDtos.ConfirmRequest(paymentId, "cash")))
                .isInstanceOfSatisfying(BusinessException.class, exception -> {
                    assertThat(exception.getMessage()).isEqualTo("Payment not found");
                    assertThat(exception.status()).isEqualTo(HttpStatus.NOT_FOUND);
                });
    }
}
