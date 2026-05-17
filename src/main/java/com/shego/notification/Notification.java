package com.shego.notification;

import com.shego.common.BaseEntity;
import com.shego.common.NotificationType;
import com.shego.common.Role;
import com.shego.user.User;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.ManyToOne;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@Entity
public class Notification extends BaseEntity {
    @ManyToOne(optional = false)
    private User user;

    private String channel;
    @Enumerated(EnumType.STRING)
    private Role role;
    @Enumerated(EnumType.STRING)
    private NotificationType type = NotificationType.INFO;
    private String title;
    @Column(length = 1000)
    private String body;
    private String targetType;
    private String targetId;
    private String route;
    private String dedupeKey;
    private boolean read;
    private boolean archived;
    private boolean sent;
}
