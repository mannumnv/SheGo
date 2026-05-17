package com.shego.location;

import com.shego.common.BaseEntity;
import com.shego.common.SavedLocationType;
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
public class SavedLocation extends BaseEntity {
    @ManyToOne(optional = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private SavedLocationType type = SavedLocationType.OTHER;

    @Column(nullable = false)
    private String label;

    @Column(nullable = false)
    private String address;

    private double latitude;
    private double longitude;
}
