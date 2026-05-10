package com.shego.driver;

import com.shego.common.AdminApprovalStatus;
import com.shego.common.BaseEntity;
import com.shego.common.Gender;
import com.shego.common.KycStatus;
import com.shego.common.SensitiveStringConverter;
import com.shego.common.VehicleType;
import com.shego.user.User;
import jakarta.persistence.Column;
import jakarta.persistence.Convert;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.OneToOne;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDate;

@Getter
@Setter
@NoArgsConstructor
@Entity
public class DriverProfile extends BaseEntity {
    @OneToOne(optional = false)
    private User user;

    @Column(nullable = false, unique = true)
    private String licenseNumber;

    private LocalDate dateOfBirth;
    private int age;

    @Enumerated(EnumType.STRING)
    private Gender gender;

    private String address;

    @Convert(converter = SensitiveStringConverter.class)
    private String aadhaarEncrypted;

    private String aadhaarLast4;

    private String drivingLicenseNumber;

    @Enumerated(EnumType.STRING)
    private VehicleType vehicleType;

    private String vehicleRegistrationNumber;
    private String insuranceDetails;
    private String selfieStorageKey;
    private String aadhaarStorageKey;
    private String licenseStorageKey;
    private String vehicleDocumentStorageKey;
    private String insuranceDocumentStorageKey;

    @Enumerated(EnumType.STRING)
    private KycStatus kycStatus = KycStatus.PENDING;

    @Enumerated(EnumType.STRING)
    private AdminApprovalStatus adminApprovalStatus = AdminApprovalStatus.PENDING;

    private boolean available;
    private boolean online;
    private boolean adminApproved;
    private boolean backgroundVerified;
    private double averageRating;
    private int completedRides;
}
