package com.shego.sos;

import com.shego.common.SosStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface SosAlertRepository extends JpaRepository<SosAlert, UUID> {
    List<SosAlert> findByStatus(SosStatus status);
}
