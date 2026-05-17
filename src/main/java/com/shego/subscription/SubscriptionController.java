package com.shego.subscription;

import com.shego.common.ApiResponse;
import com.shego.exception.BusinessException;
import com.shego.user.CurrentUserService;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.List;

@RestController
public class SubscriptionController {
    private final SubscriptionPlanRepository plans;
    private final UserSubscriptionRepository subscriptions;
    private final CurrentUserService currentUserService;

    public SubscriptionController(SubscriptionPlanRepository plans, UserSubscriptionRepository subscriptions, CurrentUserService currentUserService) {
        this.plans = plans;
        this.subscriptions = subscriptions;
        this.currentUserService = currentUserService;
    }

    @GetMapping("/api/subscriptions/plans")
    ApiResponse<List<SubscriptionPlan>> plans() {
        return ApiResponse.ok("Subscription plans", plans.findByActiveTrue());
    }

    @PostMapping("/api/subscriptions/purchase")
    ApiResponse<UserSubscription> purchase(@RequestBody SubscriptionDtos.PurchaseRequest request) {
        UserSubscription subscription = new UserSubscription();
        subscription.setUser(currentUserService.current());
        subscription.setPlan(plans.findById(request.planId())
                .orElseThrow(() -> new BusinessException("Subscription plan not found", HttpStatus.NOT_FOUND)));
        subscription.setStartsAt(Instant.now());
        subscription.setEndsAt(Instant.now().plusSeconds(30L * 86400));
        return ApiResponse.ok("Subscription purchased", subscriptions.save(subscription));
    }

    @GetMapping("/api/subscriptions/me")
    ApiResponse<List<UserSubscription>> mine() {
        return ApiResponse.ok("My subscriptions", subscriptions.findByUser(currentUserService.current()));
    }
}
