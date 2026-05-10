package com.shego.commute;

import com.shego.rider.RiderProfile;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface CommuteScheduleRepository extends JpaRepository<CommuteSchedule, UUID> {
    List<CommuteSchedule> findByRiderOrderByCreatedAtDesc(RiderProfile rider);
}
