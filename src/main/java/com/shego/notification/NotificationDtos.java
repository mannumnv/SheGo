package com.shego.notification;

import com.shego.common.NotificationType;
import com.shego.common.Role;

import java.time.Instant;
import java.util.UUID;

public class NotificationDtos {
    public record NotificationResponse(UUID id, Role role, NotificationType type, String title, String body,
                                       String targetType, String targetId, String route, boolean read,
                                       Instant createdAt) {
        public static NotificationResponse from(Notification notification) {
            return new NotificationResponse(notification.getId(), notification.getRole(), notification.getType(),
                    notification.getTitle(), notification.getBody(), notification.getTargetType(),
                    notification.getTargetId(), notification.getRoute(), notification.isRead(),
                    notification.getCreatedAt());
        }
    }

    public record UnreadCountResponse(long count) {
    }
}
