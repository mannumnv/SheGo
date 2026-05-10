package com.shego.common;

import com.shego.exception.BusinessException;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.Period;

@Service
public class EligibilityValidationService {
    private static final int LEGAL_DRIVER_AGE = 18;

    public int age(LocalDate dateOfBirth) {
        if (dateOfBirth == null) {
            throw new BusinessException("Date of birth is required.");
        }
        if (dateOfBirth.isAfter(LocalDate.now())) {
            throw new BusinessException("Date of birth cannot be in the future.");
        }
        return Period.between(dateOfBirth, LocalDate.now()).getYears();
    }

    public RiderEligibilityResult validateRider(Gender gender, LocalDate dateOfBirth, String riderAadhaarNumber,
                                                String guardianAadhaarNumber, String guardianMobileNumber,
                                                String guardianRelationship, boolean guardianConsent) {
        if (gender == null) {
            throw new BusinessException("Gender is required.");
        }
        int age = age(dateOfBirth);
        RiderAgeCategory category = riderAgeCategory(age);

        if (gender == Gender.MALE && age >= 14) {
            throw new BusinessException("Male riders age 14 or above are not allowed.");
        }
        if (gender == Gender.OTHER) {
            return new RiderEligibilityResult(age, category, null, AccountStatus.PENDING_ADMIN_REVIEW);
        }
        if (gender == Gender.FEMALE && age >= 18) {
            if (blank(riderAadhaarNumber)) {
                throw new BusinessException("Rider Aadhaar is required for adult female riders.");
            }
            return new RiderEligibilityResult(age, category, VerificationType.SELF_AADHAAR, AccountStatus.PENDING);
        }
        requireGuardian(guardianAadhaarNumber, guardianMobileNumber, guardianRelationship, guardianConsent);
        return new RiderEligibilityResult(age, category, VerificationType.GUARDIAN_AADHAAR, AccountStatus.PENDING);
    }

    public int validateDriver(Gender gender, LocalDate dateOfBirth) {
        if (gender != Gender.FEMALE) {
            throw new BusinessException("Only female drivers are allowed.");
        }
        int age = age(dateOfBirth);
        if (age < LEGAL_DRIVER_AGE) {
            throw new BusinessException("Driver must be legally adult as per Indian driving rules.");
        }
        return age;
    }

    private RiderAgeCategory riderAgeCategory(int age) {
        if (age < 14) {
            return RiderAgeCategory.CHILD;
        }
        if (age < 18) {
            return RiderAgeCategory.TEEN;
        }
        return RiderAgeCategory.ADULT;
    }

    private void requireGuardian(String aadhaar, String mobile, String relationship, boolean consent) {
        if (blank(aadhaar)) {
            throw new BusinessException("Guardian Aadhaar is required for riders below 18.");
        }
        if (blank(mobile)) {
            throw new BusinessException("Guardian mobile number is required.");
        }
        if (!"Mother".equalsIgnoreCase(relationship) && !"Father".equalsIgnoreCase(relationship) && !"Guardian".equalsIgnoreCase(relationship)) {
            throw new BusinessException("Guardian relationship must be Mother, Father, or Guardian.");
        }
        if (!consent) {
            throw new BusinessException("Guardian consent is required.");
        }
    }

    private boolean blank(String value) {
        return value == null || value.isBlank();
    }

    public record RiderEligibilityResult(int age, RiderAgeCategory ageCategory, VerificationType verificationType,
                                         AccountStatus accountStatus) {
    }
}
