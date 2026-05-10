package com.shego.delivery;

import com.shego.common.BaseEntity;
import com.shego.common.DeliveryCategory;
import com.shego.common.DeliveryStatus;
import com.shego.driver.DriverProfile;
import com.shego.rider.RiderProfile;
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
public class DeliveryRequest extends BaseEntity {
    @ManyToOne(optional = false)
    private RiderProfile requestedBy;

    @ManyToOne
    private DriverProfile deliveryPartner;

    @Enumerated(EnumType.STRING)
    private DeliveryCategory category;

    @Enumerated(EnumType.STRING)
    private DeliveryStatus status = DeliveryStatus.REQUESTED;

    private String pickupAddress;
    private String dropAddress;
    private String itemDescription;
}
