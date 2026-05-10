package com.shego.subscription;

import java.util.UUID;

public class SubscriptionDtos {
    public record PurchaseRequest(UUID planId) {
    }
}
