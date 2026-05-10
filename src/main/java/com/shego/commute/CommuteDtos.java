package com.shego.commute;

import com.shego.common.CommuteFrequency;
import com.shego.common.CommuteStatus;
import com.shego.common.CommuteType;
import com.shego.common.VehicleType;
import jakarta.validation.constraints.NotNull;

import java.time.LocalTime;
import java.util.UUID;

public class CommuteDtos {
    public record ScheduleRequest(@NotNull CommuteType commuteType, @NotNull CommuteFrequency frequency,
                                  @NotNull VehicleType vehicleType, String pickupAddress, String dropAddress,
                                  double pickupLat, double pickupLng, double dropLat, double dropLng,
                                  LocalTime pickupTime, UUID preferredDriverId) {
    }

    public record ScheduleResponse(UUID id, CommuteType commuteType, CommuteFrequency frequency, VehicleType vehicleType,
                                   CommuteStatus status, String pickupAddress, String dropAddress, LocalTime pickupTime,
                                   UUID preferredDriverId) {
        static ScheduleResponse from(CommuteSchedule schedule) {
            return new ScheduleResponse(schedule.getId(), schedule.getCommuteType(), schedule.getFrequency(),
                    schedule.getVehicleType(), schedule.getStatus(), schedule.getPickupAddress(), schedule.getDropAddress(),
                    schedule.getPickupTime(), schedule.getPreferredDriver() == null ? null : schedule.getPreferredDriver().getId());
        }
    }
}
