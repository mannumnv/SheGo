package com.shego.safety;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface SafetyEventRepository extends JpaRepository<SafetyEvent, UUID> {
}
