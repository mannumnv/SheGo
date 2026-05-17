package com.shego.location;

import com.shego.common.BaseEntity;
import com.shego.user.User;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.ManyToOne;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@Entity
public class RecentLocationSearch extends BaseEntity {
    @ManyToOne(optional = false)
    private User user;

    @Column(nullable = false)
    private String queryText;

    @Column(nullable = false)
    private String address;

    private double latitude;
    private double longitude;
}
