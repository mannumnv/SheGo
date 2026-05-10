package com.shego.admin;

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
public class AdminActionLog extends BaseEntity {
    @ManyToOne(optional = false)
    private User admin;

    private String action;
    private String targetType;
    private String targetId;
    private String notes;
}
