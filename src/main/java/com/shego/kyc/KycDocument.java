package com.shego.kyc;

import com.shego.common.BaseEntity;
import com.shego.common.KycStatus;
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
public class KycDocument extends BaseEntity {
    @ManyToOne(optional = false)
    private User user;

    @Column(nullable = false)
    private String documentType;

    @Column(nullable = false)
    private String privateStorageKey;

    private String maskedDocumentNumber;

    @Enumerated(EnumType.STRING)
    private KycStatus status = KycStatus.PENDING;

    private String rejectionReason;
}
