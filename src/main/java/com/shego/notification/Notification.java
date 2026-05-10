package com.shego.notification;

import com.shego.common.BaseEntity;
import com.shego.user.User;
import jakarta.persistence.Entity;
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
    private String title;
    private String body;
    private boolean sent;
}
