package com.shego.guardian;

import jakarta.validation.constraints.NotBlank;

import java.util.UUID;

public class GuardianDtos {
    public record UpsertRequest(@NotBlank String name, @NotBlank String mobileNumber, String relationship, boolean autoShareLateNight) {
    }

    public record GuardianResponse(UUID id, String name, String mobileNumber, String relationship, boolean autoShareLateNight) {
        static GuardianResponse from(GuardianContact contact) {
            return new GuardianResponse(contact.getId(), contact.getName(), contact.getMobileNumber(), contact.getRelationship(), contact.isAutoShareLateNight());
        }
    }

    public record TrustedDriverRequest(UUID driverId) {
    }

    public record TrustedDriverResponse(UUID id, UUID driverId, String driverName) {
        static TrustedDriverResponse from(TrustedDriver trustedDriver) {
            return new TrustedDriverResponse(trustedDriver.getId(), trustedDriver.getDriver().getId(),
                    trustedDriver.getDriver().getUser().getFullName());
        }
    }
}
