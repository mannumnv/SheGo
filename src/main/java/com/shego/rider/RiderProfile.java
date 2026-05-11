package com.shego.rider;

import com.shego.common.BaseEntity;
import com.shego.common.Gender;
import com.shego.common.KycStatus;
import com.shego.common.RiderAgeCategory;
import com.shego.common.SensitiveStringConverter;
import com.shego.common.VerificationType;
import com.shego.user.User;
import jakarta.persistence.Convert;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToOne;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDate;

@Getter
@Setter
@NoArgsConstructor
@Entity
public class RiderProfile extends BaseEntity {
    @OneToOne(optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    private KycStatus kycStatus = KycStatus.PENDING;

    private LocalDate riderDateOfBirth;
    private int riderAge;

    @Enumerated(EnumType.STRING)
    private Gender riderGender;

    @Enumerated(EnumType.STRING)
    private RiderAgeCategory riderAgeCategory;

    private String address;
    private String profilePhotoStorageKey;
    private String emergencyContact;
    private String guardianName;
    private String guardianRelationship;
    private String guardianMobileNumber;

    @Convert(converter = SensitiveStringConverter.class)
    private String guardianAadhaarEncrypted;

    private String guardianAadhaarLast4;

    @Convert(converter = SensitiveStringConverter.class)
    private String riderAadhaarEncrypted;

    private String riderAadhaarLast4;

    private boolean guardianConsent;

    @Enumerated(EnumType.STRING)
    private VerificationType verificationType;

    private String emergencyPreference;
    private double averageRating;
}
