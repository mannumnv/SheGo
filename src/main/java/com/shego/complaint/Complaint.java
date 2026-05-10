package com.shego.complaint;

import com.shego.common.BaseEntity;
import com.shego.common.ComplaintCategory;
import com.shego.common.ComplaintStatus;
import com.shego.ride.Ride;
import com.shego.user.User;
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
public class Complaint extends BaseEntity {
    @ManyToOne(optional = false)
    private User raisedBy;

    @ManyToOne
    private Ride ride;

    @Enumerated(EnumType.STRING)
    private ComplaintCategory category;

    @Enumerated(EnumType.STRING)
    private ComplaintStatus status = ComplaintStatus.OPEN;

    private String description;
    private String resolution;
}
