package com.shego.notification;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface NotificationRepository extends JpaRepository<Notification, UUID> {
    List<Notification> findByUserIdAndArchivedFalseOrderByCreatedAtDesc(UUID userId);
    long countByUserIdAndReadFalseAndArchivedFalse(UUID userId);
    Optional<Notification> findByUserIdAndDedupeKey(UUID userId, String dedupeKey);
}
