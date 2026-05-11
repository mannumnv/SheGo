# SheGo API Reference

This document describes the current SheGo backend APIs and the main product flows implemented in this codebase. It is written for future development and debugging, so new backend or Flutter work should stay aligned with this file.

## Base Rules

- Base URL local: `http://localhost:8080`
- Swagger UI: `http://localhost:8080/swagger-ui/index.html`
- API docs JSON: `/v3/api-docs`
- Response wrapper:

```json
{
  "success": true,
  "message": "Message",
  "data": {}
}
```

- Auth header for protected APIs:

```http
Authorization: Bearer <jwt-access-token>
```

- Vehicle support is only `SCOOTY` and `BIKE`.
- Permanent data is stored in PostgreSQL.
- Uploaded files are stored in private S3 paths; PostgreSQL stores object keys only.
- Redis is for temporary OTP/session/live-location/guardian tracking data.
- Full Aadhaar can be accepted in KYC requests, but it must be encrypted before persistence. API responses must only expose last 4 digits.

## Auth Flow

1. User signs up as rider or driver, or admin is bootstrapped locally from `.env`.
2. User logs in with mobile/password.
3. Backend returns `accessToken` and `refreshToken`.
4. Client sends `Authorization: Bearer <accessToken>` for protected APIs.
5. Admin APIs require `ROLE_ADMIN`.

### Auth APIs

| Method | Endpoint | Auth | Purpose |
|---|---|---:|---|
| POST | `/api/auth/register` | Public | Generic registration with roles |
| POST | `/api/auth/login` | Public | Login by mobile/password |
| POST | `/api/auth/otp/send` | Public | Send OTP placeholder flow |
| POST | `/api/auth/otp/verify` | Public | Verify OTP placeholder flow |
| POST | `/api/auth/refresh-token` | Public | Issue access token from refresh token |
| POST | `/api/auth/forgot-password/send-otp` | Public | Send or simulate password reset OTP |
| POST | `/api/auth/forgot-password/verify-otp` | Public | Verify reset OTP |
| POST | `/api/auth/forgot-password/reset` | Public | Reset password after OTP verification |
| POST | `/api/dev/users/reset-password` | Local/dev only | Emergency password reset for local testing |

Login request:

```json
{
  "mobileNumber": "9999999999",
  "password": "your-password"
}
```

Login response data:

```json
{
  "accessToken": "jwt",
  "refreshToken": "jwt"
}
```

## Rider Signup And Verification Flow

1. Rider signs up through `/api/riders/signup`.
2. Backend calculates age from `dateOfBirth`.
3. Eligibility rules:
   - Female riders: allowed at any age.
   - Female under 18: guardian Aadhaar and guardian consent required.
   - Female 18 or above: self Aadhaar required.
   - Male below 14: guardian Aadhaar and guardian consent required.
   - Male 14 or above: rejected.
   - Other gender: account goes to `PENDING_ADMIN_REVIEW`.
4. Rider is stored in `users` and `rider_profile`.
5. Admin approves rider/guardian verification.
6. Approved rider can book rides.

### Rider APIs

| Method | Endpoint | Auth | Purpose |
|---|---|---:|---|
| POST | `/api/riders/signup` | Public | Rider signup with eligibility validation |
| POST | `/api/riders/login` | Public | Rider login |
| POST | `/api/riders/verify-guardian` | Rider | Update guardian verification fields |
| GET | `/api/riders/profile` | Rider | Current rider profile |

Adult female rider signup:

```json
{
  "fullName": "Ananya Sharma",
  "mobileNumber": "9876543210",
  "password": "secret123",
  "gender": "FEMALE",
  "dateOfBirth": "2000-04-15",
  "address": "Delhi",
  "emergencyContact": "9876500000",
  "riderAadhaarNumber": "123412341234"
}
```

Minor rider signup:

```json
{
  "fullName": "Aarohi Sharma",
  "mobileNumber": "9876543211",
  "password": "secret123",
  "gender": "FEMALE",
  "dateOfBirth": "2011-08-20",
  "guardianName": "Parent Name",
  "guardianRelationship": "Mother",
  "guardianMobileNumber": "9876500001",
  "guardianAadhaarNumber": "123412341234",
  "guardianConsent": true
}
```

## Driver Signup, KYC, And Approval Flow

1. Driver signs up through `/api/drivers/signup`.
2. Backend validates:
   - Driver must be `FEMALE`.
   - Driver must be adult.
   - Vehicle type must be `SCOOTY` or `BIKE`.
3. Backend stores:
   - `users`
   - `driver_profile`
   - linked `vehicle`
4. Driver starts with:
   - `kycStatus = PENDING`
   - `adminApprovalStatus = PENDING`
   - `adminApproved = false`
   - `available = false`
   - `online = false`
5. Admin reviews pending driver verification via `/api/admin/pending-driver-kyc`.
6. Admin approves driver via `/api/admin/approve-driver-verification?driverId=<id>`.
7. Driver can go online only after KYC and admin approval.

### Driver APIs

| Method | Endpoint | Auth | Purpose |
|---|---|---:|---|
| POST | `/api/drivers/signup` | Public | Driver signup with KYC/vehicle details |
| POST | `/api/drivers/login` | Public | Driver login |
| POST | `/api/drivers/upload-kyc` | Driver | Upload/update KYC object keys and Aadhaar data |
| GET | `/api/drivers/profile` | Driver | Current driver profile |
| POST | `/api/drivers/onboard` | Driver | Legacy/additional vehicle onboarding |
| PUT | `/api/drivers/availability` | Driver | Set available/online |
| PUT | `/api/drivers/location` | Driver | Update live driver location in Redis |
| GET | `/api/drivers/nearby?type=SCOOTY` | Auth | Search approved nearby drivers |
| GET | `/api/drivers/me/earnings` | Driver | Driver earnings history |
| GET | `/api/drivers/{id}/ratings` | Auth | Driver ratings |

Driver signup:

```json
{
  "fullName": "Nisha Verma",
  "mobileNumber": "9876543220",
  "password": "secret123",
  "gender": "FEMALE",
  "dateOfBirth": "1997-06-10",
  "address": "Bengaluru",
  "drivingLicenseNumber": "KA0120110012345",
  "vehicleType": "SCOOTY",
  "vehicleRegistrationNumber": "KA01AB1234",
  "insuranceDetails": "POLICY-123",
  "aadhaarNumber": "123412341234",
  "aadhaarStorageKey": "kyc/driver/aadhaar.png",
  "licenseStorageKey": "kyc/driver/license.png",
  "vehicleDocumentStorageKey": "kyc/driver/vehicle.png",
  "insuranceDocumentStorageKey": "kyc/driver/insurance.png",
  "selfieStorageKey": "kyc/driver/selfie.png"
}
```

Availability:

```json
{
  "available": true,
  "online": true
}
```

## KYC And Storage APIs

KYC files should be uploaded to S3 using upload intent URLs. The backend stores only private object keys. Admins use download intent for temporary pre-signed access.

| Method | Endpoint | Auth | Purpose |
|---|---|---:|---|
| POST | `/api/storage/upload-intent` | Auth | Create S3 pre-signed upload URL |
| POST | `/api/storage/download-intent` | Admin | Create temporary S3 pre-signed download URL |
| POST | `/api/kyc/upload` | Auth | Save KYC document metadata |
| GET | `/api/kyc/status` | Auth | Current user's KYC docs |
| GET | `/api/admin/kyc/pending` | Admin | Pending KYC document queue |
| POST | `/api/admin/kyc/{id}/approve` | Admin | Approve KYC document |
| POST | `/api/admin/kyc/{id}/reject` | Admin | Reject KYC document |

Upload intent:

```json
{
  "folder": "kyc/driver",
  "fileName": "aadhaar.png",
  "contentType": "image/png"
}
```

KYC metadata:

```json
{
  "documentType": "AADHAAR",
  "privateStorageKey": "kyc/driver/aadhaar.png",
  "maskedDocumentNumber": "****1234"
}
```

## Ride Booking And OTP Start Flow

1. Approved rider estimates fare through `/api/rides/estimate`.
2. Rider books a ride through `/api/rides/book`.
3. Backend creates a `ride` row with status `REQUESTED`.
4. Backend searches approved online female drivers using driver state and Redis live location.
5. Driver accepts via `/api/rides/{id}/accept`.
6. Backend assigns:
   - `driver_id`
   - `vehicle_id`
   - vehicle registration/model snapshots
   - status `ACCEPTED`
7. Rider receives safe driver and vehicle details.
8. Driver receives safe rider pickup/drop details.
9. Driver reaches pickup and calls `/api/rides/{id}/arrive`.
10. Backend sets status `DRIVER_REACHED` and generates start OTP visible only in rider view.
11. Rider shares OTP with driver.
12. Driver calls `/api/rides/{id}/start` with OTP.
13. Backend verifies OTP, retry count, expiry, and assigned driver.
14. Ride status becomes `STARTED`.
15. Driver completes ride with `/api/rides/{id}/complete`.
16. Rider can rate driver.

Ride statuses:

```text
REQUESTED, ACCEPTED, DRIVER_REACHED, DRIVER_ARRIVING, STARTED, COMPLETED, CANCELLED
```

### Ride APIs

| Method | Endpoint | Auth | Purpose |
|---|---|---:|---|
| POST | `/api/rides/estimate` | Rider | Fare and ETA estimate |
| POST | `/api/rides/book` | Rider | Book ride |
| POST | `/api/rides/{id}/accept` | Driver | Assigned driver accepts |
| POST | `/api/rides/{id}/reject` | Driver | Driver rejects |
| POST | `/api/rides/{id}/arrive` | Driver | Driver reached pickup, generate OTP |
| POST | `/api/rides/{id}/start` | Driver | Start ride with OTP |
| POST | `/api/rides/{id}/complete` | Driver | Complete ride |
| POST | `/api/rides/{id}/cancel` | Rider/Driver | Cancel ride |
| GET | `/api/rides/{id}` | Rider/Driver/Admin | Safe ride details |
| GET | `/api/rides/history` | Rider/Driver | User ride history |

Estimate/book request:

```json
{
  "vehicleType": "SCOOTY",
  "pickupLat": 28.6139,
  "pickupLng": 77.209,
  "dropLat": 28.5355,
  "dropLng": 77.391,
  "pickupAddress": "Connaught Place",
  "dropAddress": "Noida Sector 18"
}
```

Start ride request:

```json
{
  "otp": "1234"
}
```

Safe ride detail response includes only ride-relevant participant data. It must not expose home address, Aadhaar, encrypted fields, or KYC document keys.

## Live Location APIs

| Method | Endpoint | Auth | Purpose |
|---|---|---:|---|
| GET | `/api/rides/{rideId}/locations` | Auth | Stored ride location trail |
| WebSocket | `/ws/location` | Auth/client | STOMP WebSocket endpoint |
| STOMP send | `/app/location/update` | Auth/client | Send live location message |
| STOMP topic | `/topic/rides/location` | Auth/client | Receive live location updates |

Live location data is temporary/operational and should be cleaned by retention policy.

## Guardian And Trusted Circle APIs

| Method | Endpoint | Auth | Purpose |
|---|---|---:|---|
| POST | `/api/guardians` | Rider | Add trusted contact |
| GET | `/api/guardians` | Rider | List trusted contacts |
| DELETE | `/api/guardians/{id}` | Rider | Delete trusted contact |
| POST | `/api/rides/{id}/share-live-location` | Rider | Enable guardian live sharing |
| POST | `/api/trusted-drivers` | Rider | Mark favorite/trusted driver |
| GET | `/api/trusted-drivers` | Rider | List trusted drivers |

Guardian contact request:

```json
{
  "name": "Mother",
  "mobileNumber": "9876500001",
  "relationship": "Mother",
  "autoShareLateNight": true
}
```

## SOS And Safety APIs

| Method | Endpoint | Auth | Purpose |
|---|---|---:|---|
| POST | `/api/sos/trigger` | Auth | Trigger SOS before/during/after ride |
| POST | `/api/sos/{id}/resolve` | Admin | Resolve SOS |
| GET | `/api/admin/sos/active` | Admin | Active SOS queue |
| GET | `/api/safety/driver/{driverId}/score` | Auth | Driver safety score |
| POST | `/api/safety/events` | Auth | Record safety event |
| GET | `/api/admin/safety/events` | Admin | Safety events queue |
| GET | `/api/safety/late-night-policy` | Auth | Late-night safety rules |

SOS trigger:

```json
{
  "rideId": "uuid-or-null",
  "latitude": 28.6139,
  "longitude": 77.209,
  "message": "Need help"
}
```

## Rating, Complaint, Payment, Subscription

### Rating

| Method | Endpoint | Auth | Purpose |
|---|---|---:|---|
| POST | `/api/ratings` | Auth | Rate rider/driver after ride |
| GET | `/api/drivers/{id}/ratings` | Auth | Driver rating list |

Rating request:

```json
{
  "rideId": "uuid",
  "ratedUserId": "uuid",
  "overallRating": 5,
  "safetyRating": 5,
  "comfortRating": 5,
  "drivingBehaviorRating": 5,
  "comments": "Safe ride"
}
```

### Complaints

| Method | Endpoint | Auth | Purpose |
|---|---|---:|---|
| POST | `/api/complaints` | Auth | Raise complaint |
| GET | `/api/complaints/me` | Auth | My complaints |
| GET | `/api/admin/complaints` | Admin | All complaints |
| POST | `/api/admin/complaints/{id}/resolve` | Admin | Resolve complaint |

Complaint categories: `SAFETY`, `PAYMENT`, `BEHAVIOR`, `CANCELLATION`, `ROUTE`, `OTHER`.

### Payments

| Method | Endpoint | Auth | Purpose |
|---|---|---:|---|
| POST | `/api/payments/initiate` | Auth | Start payment |
| POST | `/api/payments/confirm` | Auth | Confirm payment |
| GET | `/api/payments/history` | Auth | User payment history |
| POST | `/api/payments/refund` | Admin/support | Refund payment |

Current supported payment behavior is MVP-ready and cash/future-online extensible.

### Subscriptions

| Method | Endpoint | Auth | Purpose |
|---|---|---:|---|
| GET | `/api/subscriptions/plans` | Auth | List plans |
| POST | `/api/subscriptions/purchase` | Auth | Purchase plan |
| GET | `/api/subscriptions/me` | Auth | My subscriptions |

## Admin APIs

All `/api/admin/**` APIs require `ROLE_ADMIN`.

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/api/admin/dashboard` | Counts and operational overview |
| GET | `/api/admin/users` | User list |
| POST | `/api/admin/users/{id}/suspend` | Suspend user |
| POST | `/api/admin/users/{id}/block` | Block user |
| GET | `/api/admin/minor-riders` | Riders below 18 |
| GET | `/api/admin/pending-guardian-verifications` | Guardian verification queue |
| GET | `/api/admin/pending-driver-kyc` | Pending driver KYC/admin approval queue |
| POST | `/api/admin/approve-rider-verification?riderId=<id>` | Approve rider verification |
| POST | `/api/admin/approve-driver-verification?driverId=<id>` | Approve driver verification |
| POST | `/api/admin/reject-driver-verification?driverId=<id>&reason=<reason>` | Reject driver verification |
| POST | `/api/admin/drivers/{id}/approve` | Legacy driver approval |
| GET | `/api/admin/rides/active` | Active rides |
| GET | `/api/admin/reports` | Report placeholder |
| GET | `/api/admin/notifications` | Notifications |

Pending driver response is intentionally safe:

```json
{
  "driverId": "uuid",
  "userId": "uuid",
  "fullName": "Priya Sharma",
  "mobileNumber": "9876543210",
  "gender": "FEMALE",
  "age": 24,
  "vehicleType": "SCOOTY",
  "vehicleRegistrationNumber": "DL01AB1234",
  "kycStatus": "PENDING",
  "adminApprovalStatus": "PENDING",
  "adminApproved": false,
  "available": false,
  "online": false,
  "aadhaarLast4": "1234",
  "profilePhotoStorageKey": null
}
```

## Child Ride, Commute, Delivery Future Modules

These APIs are present for Phase 3/4 structure and UI flow support.

### Child Ride

| Method | Endpoint | Auth | Purpose |
|---|---|---:|---|
| POST | `/api/child-rides/book` | Auth | Book child ride |
| POST | `/api/child-rides/{id}/pickup-verify` | Auth | Verify pickup OTP |
| POST | `/api/child-rides/{id}/drop-verify` | Auth | Verify drop OTP |
| GET | `/api/child-rides/history` | Auth | Child ride history |

### Commute

| Method | Endpoint | Auth | Purpose |
|---|---|---:|---|
| POST | `/api/commutes` | Auth | Create office/college commute schedule |
| GET | `/api/commutes/me` | Auth | My commute schedules |
| POST | `/api/commutes/{id}/pause` | Auth | Pause commute |
| POST | `/api/commutes/{id}/cancel` | Auth | Cancel commute |

### Delivery

| Method | Endpoint | Auth | Purpose |
|---|---|---:|---|
| POST | `/api/deliveries` | Auth | Create women-delivery-network request |
| GET | `/api/deliveries/me` | Auth | My delivery requests |

## User Profile APIs

| Method | Endpoint | Auth | Purpose |
|---|---|---:|---|
| GET | `/api/users/me` | Auth | Current user |
| PUT | `/api/users/me` | Auth | Update full name/email |
| DELETE | `/api/users/me` | Auth | Soft/delete current account behavior |

## Production Notes For Future Work

- Never add `AUTO`, `CAR`, `TAXI`, or mixed-gender ride support to current production APIs.
- Keep rider/driver signup DTOs separate.
- Driver signup must not contain guardian or rider Aadhaar fields.
- Driver can accept rides only when active, KYC-approved, admin-approved, and not already on another active ride.
- OTP must not be exposed to driver before rider shares it.
- Admin/download access to KYC files must use short-lived pre-signed S3 URLs.
- If an endpoint returns `Unexpected server error`, check logs first; `GlobalExceptionHandler` logs the full stack trace.


# Flow:
Current kyc_status approval logic is mostly admin/manual approval based.

## Driver Flow

1. Driver signs up.

2. Driver profile is created with:

kycStatus = PENDING
adminApprovalStatus = PENDING
adminApproved = false
available = false
online = false
3. Admin checks pending drivers from:

GET /api/admin/pending-driver-kyc

4. Admin approves driver verification using:
POST /api/admin/approve-driver-verification?driverId=<driverProfileId>

That sets:

driver.setKycStatus(KycStatus.APPROVED);
driver.setAdminApprovalStatus(AdminApprovalStatus.APPROVED);
driver.setAdminApproved(true);
driver.getUser().setAccountStatus(AccountStatus.ACTIVE);

#### After this, driver can go online.

# Rider Flow: 
1. Admin approves rider verification using:

POST /api/admin/approve-rider-verification?riderId=<riderProfileId>
That sets:

rider.setKycStatus(KycStatus.APPROVED);
rider.getUser().setAccountStatus(AccountStatus.ACTIVE);

2. KYC Document Flow
For individual uploaded KYC documents:

POST /api/kyc/upload
creates document with PENDING.

3.Admin can approve:

POST /api/admin/kyc/{id}/approve
This approves the KycDocument, but profile-level approval is separate.

So short version: uploaded KYC docs can be approved individually, but rider/driver account activation currently happens through admin profile approval APIs.
