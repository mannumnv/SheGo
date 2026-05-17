package com.shego.notification;

import com.shego.common.ApiResponse;
import com.shego.exception.BusinessException;
import com.shego.user.CurrentUserService;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
public class NotificationController {
    private final NotificationRepository notifications;
    private final CurrentUserService currentUserService;

    public NotificationController(NotificationRepository notifications, CurrentUserService currentUserService) {
        this.notifications = notifications;
        this.currentUserService = currentUserService;
    }

    @GetMapping("/api/notifications")
    ApiResponse<List<NotificationDtos.NotificationResponse>> mine() {
        var current = currentUserService.current();
        return ApiResponse.ok("Notifications", notifications.findByUserIdAndArchivedFalseOrderByCreatedAtDesc(current.getId()).stream()
                .map(NotificationDtos.NotificationResponse::from)
                .toList());
    }

    @GetMapping("/api/notifications/unread-count")
    ApiResponse<NotificationDtos.UnreadCountResponse> unreadCount() {
        var current = currentUserService.current();
        return ApiResponse.ok("Unread notifications",
                new NotificationDtos.UnreadCountResponse(notifications.countByUserIdAndReadFalseAndArchivedFalse(current.getId())));
    }

    @PostMapping("/api/notifications/{id}/read")
    ApiResponse<NotificationDtos.NotificationResponse> markRead(@PathVariable UUID id) {
        var notification = owned(id);
        notification.setRead(true);
        return ApiResponse.ok("Notification marked read", NotificationDtos.NotificationResponse.from(notifications.save(notification)));
    }

    @DeleteMapping("/api/notifications/{id}")
    ApiResponse<Void> archive(@PathVariable UUID id) {
        var notification = owned(id);
        notification.setArchived(true);
        notifications.save(notification);
        return ApiResponse.ok("Notification archived", null);
    }

    private Notification owned(UUID id) {
        var current = currentUserService.current();
        var notification = notifications.findById(id)
                .orElseThrow(() -> new BusinessException("Notification not found", HttpStatus.NOT_FOUND));
        if (!notification.getUser().getId().equals(current.getId())) {
            throw new BusinessException("Notification not found", HttpStatus.NOT_FOUND);
        }
        return notification;
    }

    @PreAuthorize("hasAnyRole('ADMIN','SUPPORT')")
    @GetMapping("/api/admin/notifications")
    ApiResponse<List<NotificationDtos.NotificationResponse>> all() {
        return ApiResponse.ok("Notifications", notifications.findAll().stream()
                .map(NotificationDtos.NotificationResponse::from)
                .toList());
    }
}
