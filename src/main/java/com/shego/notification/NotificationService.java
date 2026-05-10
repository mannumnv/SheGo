package com.shego.notification;

import com.shego.user.User;
import org.springframework.stereotype.Service;

@Service
public class NotificationService {
    private final NotificationRepository notifications;

    public NotificationService(NotificationRepository notifications) {
        this.notifications = notifications;
    }

    public Notification create(User user, String channel, String title, String body) {
        Notification notification = new Notification();
        notification.setUser(user);
        notification.setChannel(channel);
        notification.setTitle(title);
        notification.setBody(body);
        notification.setSent(false);
        return notifications.save(notification);
    }
}
