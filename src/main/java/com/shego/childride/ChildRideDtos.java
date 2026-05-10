package com.shego.childride;

import java.time.Instant;

public class ChildRideDtos {
    public record BookRequest(String childName, Instant scheduledAt) {
    }

    public record VerifyRequest(String otp) {
    }
}
