package com.shego.subscription;

import com.shego.exception.BusinessException;
import com.shego.user.CurrentUserService;
import com.shego.user.User;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static com.shego.testsupport.TestDoubles.authenticate;
import static com.shego.testsupport.TestDoubles.proxy;

class SubscriptionControllerTest {
    @Test
    void purchaseReturnsNotFoundWhenPlanDoesNotExist() {
        UUID planId = UUID.randomUUID();
        authenticate(new User());
        SubscriptionPlanRepository plans = proxy(SubscriptionPlanRepository.class, java.util.Map.of("findById", Optional.empty()));
        UserSubscriptionRepository subscriptions = proxy(UserSubscriptionRepository.class, java.util.Map.of());

        SubscriptionController controller = new SubscriptionController(plans, subscriptions, new CurrentUserService());

        assertThatThrownBy(() -> controller.purchase(new SubscriptionDtos.PurchaseRequest(planId)))
                .isInstanceOfSatisfying(BusinessException.class, exception -> {
                    assertThat(exception.getMessage()).isEqualTo("Subscription plan not found");
                    assertThat(exception.status()).isEqualTo(HttpStatus.NOT_FOUND);
                });
    }
}
