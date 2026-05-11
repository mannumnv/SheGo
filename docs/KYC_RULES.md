# SheGo KYC Rules

This document describes the current KYC and eligibility rules implemented in the backend.

## Platform Rules

- Riders are women/girls of any age, boys below 14, and other-gender users pending admin review.
- Male riders age 14 or above are rejected.
- Drivers must be adult verified women only.
- Vehicle support is only `SCOOTY` and `BIKE`.

## Rider Eligibility

`EligibilityValidationService` calculates age from date of birth and applies these rules:

- `FEMALE` and age 18 or above:
  - self Aadhaar is required
  - `verificationType = SELF_AADHAAR`
  - account starts as `PENDING`

- `FEMALE` and age below 18:
  - guardian Aadhaar is required
  - guardian mobile number is required
  - guardian relationship must be `Mother`, `Father`, or `Guardian`
  - guardian consent is required
  - `verificationType = GUARDIAN_AADHAAR`
  - account starts as `PENDING`

- `MALE` and age below 14:
  - guardian Aadhaar is required
  - guardian mobile number is required
  - guardian relationship must be `Mother`, `Father`, or `Guardian`
  - guardian consent is required
  - `verificationType = GUARDIAN_AADHAAR`
  - account starts as `PENDING`

- `MALE` and age 14 or above:
  - signup is rejected with: `Male riders age 14 or above are not allowed.`

- `OTHER`:
  - signup is allowed
  - account status is `PENDING_ADMIN_REVIEW`
  - verification type remains pending for admin handling

Rider age categories are:

- `CHILD`: below 14
- `TEEN`: 14 to below 18
- `ADULT`: 18 or above

## Driver Eligibility

Drivers must pass validation before account creation:

- gender must be `FEMALE`
- date of birth must produce age 18 or above
- driver must complete KYC
- driver must be admin approved before going online

Driver signup is fully separated from rider signup. Driver signup supports only driver-owned fields:

- full name
- mobile number
- gender
- date of birth
- address
- self Aadhaar number
- driving license number
- vehicle type
- vehicle registration number
- insurance details
- profile photo storage key
- Aadhaar/license/vehicle/insurance/selfie storage keys

Driver signup must not contain rider guardian fields or `riderAadhaarNumber`.

Backend validation errors include:

- `Only female drivers are allowed.`
- `Driver must be legally adult as per Indian driving rules.`
- `Driver must be KYC approved and admin approved before going online.`

## Aadhaar Storage Rule

SheGo accepts full Aadhaar during signup/KYC because validation needs the complete value. The backend then:

- stores the full Aadhaar in encrypted form only
- stores Aadhaar last 4 digits separately for masked display
- never returns full Aadhaar in API responses
- never stores plain Aadhaar in PostgreSQL
- never stores Aadhaar in Redis

Current encrypted fields:

- `rider_profile.guardian_aadhaar_encrypted`
- `rider_profile.rider_aadhaar_encrypted`
- `driver_profile.aadhaar_encrypted`

Current masked display fields:

- `rider_profile.guardian_aadhaar_last4`
- `rider_profile.rider_aadhaar_last4`
- `driver_profile.aadhaar_last4`

## KYC Document Storage

Uploaded KYC files are stored in private AWS S3. PostgreSQL stores object keys only.

Supported file references include:

- rider `profile_photo_storage_key`
- driver `aadhaar_storage_key`
- driver `license_storage_key`
- driver `vehicle_document_storage_key`
- driver `insurance_document_storage_key`
- driver `selfie_storage_key`
- generic `kyc_document.private_storage_key`

Admins/support can request short-lived pre-signed download URLs via `/api/storage/download-intent`. Do not store those URLs in PostgreSQL.

## Admin Verification

Admin verification APIs currently support:

- minor rider review through `/api/admin/minor-riders`
- guardian verification review through `/api/admin/pending-guardian-verifications`
- driver KYC review through `/api/admin/pending-driver-kyc`
- rider verification approval through `/api/admin/approve-rider-verification`
- driver verification approval through `/api/admin/approve-driver-verification`

Admin verification actions must create audit logs through `AdminActionLog`.

## Future Implementation Rule

Any future KYC implementation must preserve:

- encrypted full Aadhaar storage
- last-4-only display
- private S3 object key storage
- admin-only temporary document access
- no permanent KYC data in Redis
- driver restriction to adult verified women
- ride vehicle restriction to `SCOOTY` and `BIKE`
