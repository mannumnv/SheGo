package com.shego.notification;

import com.shego.common.NotificationType;
import com.shego.common.Role;
import com.shego.user.User;
import com.shego.user.UserRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class NotificationService {
    private final NotificationRepository notifications;
    private final UserRepository users;

    public NotificationService(NotificationRepository notifications, UserRepository users) {
        this.notifications = notifications;
        this.users = users;
    }

    public Notification create(User user, String channel, String title, String body) {
        return create(user, null, NotificationType.INFO, title, body, null, null, null, null);
    }

    public Notification create(User user, Role role, NotificationType type, String title, String body,
                               String targetType, String targetId, String route, String dedupeKey) {
        if (dedupeKey != null && !dedupeKey.isBlank()) {
            var existing = notifications.findByUserIdAndDedupeKey(user.getId(), dedupeKey);
            if (existing.isPresent()) {
                Notification notification = existing.get();
                notification.setTitle(title);
                notification.setBody(body);
                notification.setType(type);
                notification.setRead(false);
                notification.setArchived(false);
                notification.setTargetType(targetType);
                notification.setTargetId(targetId);
                notification.setRoute(route);
                return notifications.save(notification);
            }
        }
        Notification notification = new Notification();
        notification.setUser(user);
        notification.setChannel("IN_APP");
        notification.setRole(role);
        notification.setType(type);
        notification.setTitle(title);
        notification.setBody(body);
        notification.setTargetType(targetType);
        notification.setTargetId(targetId);
        notification.setRoute(route);
        notification.setDedupeKey(dedupeKey);
        notification.setRead(false);
        notification.setArchived(false);
        notification.setSent(false);
        return notifications.save(notification);
    }

    public List<Notification> createForRole(Role role, NotificationType type, String title, String body,
                                            String targetType, String targetId, String route, String dedupeKeyPrefix) {
        return users.findByRole(role).stream()
                .map(user -> create(user, role, type, title, body, targetType, targetId, route,
                        dedupeKeyPrefix == null ? null : dedupeKeyPrefix + ":" + user.getId()))
                .toList();
    }
}
