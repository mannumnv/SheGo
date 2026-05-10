package com.shego.safety;

import java.util.UUID;

public class SafetyDtos {
    public record EventRequest(UUID rideId, String eventType, String severity, String details) {
    }

    public record ScoreResponse(UUID driverId, int score, String explanation) {
        static ScoreResponse from(SafetyScore score) {
            return new ScoreResponse(score.getDriver().getId(), score.getScore(), score.getExplanation());
        }
    }
}
