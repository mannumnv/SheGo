package com.shego.complaint;

import com.shego.common.ComplaintCategory;

import java.util.UUID;

public class ComplaintDtos {
    public record ComplaintRequest(UUID rideId, ComplaintCategory category, String description) {
    }

    public record ResolveRequest(String resolution) {
    }
}
