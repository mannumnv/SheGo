# SheGo Flow Guide

This file explains SheGo API flows in step-by-step sequence. Use this when you need to understand what to call first, which ID comes from where, and what state changes happen in PostgreSQL.

## Common Concepts

- `userId` comes from the `users.id` table.
- `riderId` comes from `rider_profile.id`.
- `driverId` comes from `driver_profile.id`.
- `vehicleId` comes from `vehicle.id`.
- `rideId` comes from `ride.id`.
- Authenticated APIs need:

```http
Authorization: Bearer <accessToken>
```

- Admin APIs need an admin token.
- Current vehicle types are only:

```text
SCOOTY
BIKE
```

## 1. Local Admin Flow

Use this first for local testing.

1. Create `.env` from `.env.example`.

```bash
cp .env.example .env
```

2. Set admin credentials in `.env`.

```env
ADMIN_MOBILE=9999999999
ADMIN_PASSWORD=change-this-local-admin-password
```

3. Start backend.

```bash
make backend
```

4. On startup, if no admin exists, backend creates one with:

```text
role = ADMIN
account_status = ACTIVE
password = BCrypt hash
```

5. Login as admin.

```http
POST /api/auth/login
```

```json
{
  "mobileNumber": "9999999999",
  "password": "change-this-local-admin-password"
}
```

6. Use `accessToken` from response for all `/api/admin/**` APIs.

Note: If admin already exists in DB, bootstrap does not overwrite password. Use the actual DB password or reset it manually.

## 2. Rider Signup And Approval Flow

This flow creates a rider account and makes it eligible for booking.

1. Rider signs up.

```http
POST /api/riders/signup
```

Adult female rider:

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

2. Backend validates eligibility.

```text
Female any age: allowed
Female below 18: guardian Aadhaar required
Female 18+: self Aadhaar required
Male below 14: guardian Aadhaar required
Male 14+: rejected
Other gender: PENDING_ADMIN_REVIEW
```

3. Backend creates:

```text
users row
rider_profile row
```

4. Signup response returns JWT tokens.

5. Rider can check profile.

```http
GET /api/riders/profile
Authorization: Bearer <rider-token>
```

6. Admin reviews rider verification.

```http
GET /api/admin/minor-riders
GET /api/admin/pending-guardian-verifications
```

7. Admin approves rider.

```http
POST /api/admin/approve-rider-verification?riderId=<riderId>
Authorization: Bearer <admin-token>
```

8. Backend updates:

```text
rider_profile.kyc_status = APPROVED
users.account_status = ACTIVE
```

9. Rider can now book rides.

## 2A. Forgot Password Flow

This flow is shared by admin, rider, and driver. Mobile number is the primary identifier; email can also be used where login supports it.

1. User opens forgot password from the relevant login screen.

2. User requests OTP.

```http
POST /api/auth/forgot-password/send-otp
```

```json
{
  "identifier": "9999999999"
}
```

3. Backend returns a generic message so public callers cannot confirm whether the account exists.

```text
If the account exists, an OTP has been sent.
```

4. Backend stores OTP hash temporarily in Redis with expiry, resend limit, and retry limit.

5. In local/dev profile only, backend logs OTP and can return `devOtp` for local testing.

6. User verifies OTP.

```http
POST /api/auth/forgot-password/verify-otp
```

```json
{
  "identifier": "9999999999",
  "otp": "123456"
}
```

7. User resets password.

```http
POST /api/auth/forgot-password/reset
```

```json
{
  "identifier": "9999999999",
  "otp": "123456",
  "newPassword": "NewPassword123"
}
```

8. Backend validates password strength and stores BCrypt hash.

9. User returns to the relevant login screen:

```text
AdminLoginScreen
RiderLoginScreen
DriverLoginScreen
```

Local/dev emergency reset:

```http
POST /api/dev/users/reset-password
```

```json
{
  "mobileNumber": "9999999999",
  "newPassword": "Admin1234"
}
```

This endpoint is active only when Spring profile is `local` or `dev`.

## 3. Minor Rider Guardian Flow

Use this for girls below 18 or boys below 14.

1. Rider signs up with guardian details.

```http
POST /api/riders/signup
```

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

2. Backend sets:

```text
verification_type = GUARDIAN_AADHAAR
guardian_consent = true
kyc_status = PENDING
```

3. Admin lists pending guardian verifications.

```http
GET /api/admin/pending-guardian-verifications
```

4. Admin approves.

```http
POST /api/admin/approve-rider-verification?riderId=<riderId>
```

5. Rider becomes active.

## 4. Driver Signup And Approval Flow

This is the main driver onboarding flow.

1. Driver signs up.

```http
POST /api/drivers/signup
```

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

2. Backend validates:

```text
gender must be FEMALE
age must be adult
vehicleType must be SCOOTY or BIKE
```

3. Backend creates:

```text
users row
driver_profile row
vehicle row
```

4. Backend sets:

```text
driver_profile.kyc_status = PENDING
driver_profile.admin_approval_status = PENDING
driver_profile.admin_approved = false
driver_profile.available = false
driver_profile.online = false
```

5. Driver can check profile.

```http
GET /api/drivers/profile
Authorization: Bearer <driver-token>
```

6. Admin lists pending driver verifications.

```http
GET /api/admin/pending-driver-kyc
Authorization: Bearer <admin-token>
```

This response contains `driverId`.

7. Admin approves driver.

```http
POST /api/admin/approve-driver-verification?driverId=<driverId>
Authorization: Bearer <admin-token>
```

8. Backend updates:

```text
driver_profile.kyc_status = APPROVED
driver_profile.admin_approval_status = APPROVED
driver_profile.admin_approved = true
users.account_status = ACTIVE
```

9. Driver can go online.

```http
PUT /api/drivers/availability
Authorization: Bearer <driver-token>
```

```json
{
  "available": true,
  "online": true
}
```

If admin rejects driver verification:

```http
POST /api/admin/reject-driver-verification?driverId=<driverId>&reason=<reason>
Authorization: Bearer <admin-token>
```

Backend updates:

```text
driver_profile.kyc_status = REJECTED
driver_profile.admin_approval_status = REJECTED
driver_profile.admin_approved = false
driver_profile.available = false
driver_profile.online = false
```

## 5. KYC Document Flow

This flow stores KYC document metadata and S3 object keys.

1. Client asks backend for upload URL.

```http
POST /api/storage/upload-intent
Authorization: Bearer <token>
```

```json
{
  "folder": "kyc/driver",
  "fileName": "aadhaar.png",
  "contentType": "image/png"
}
```

2. Backend returns:

```text
privateStorageKey
pre-signed uploadUrl
method
```

3. Client uploads file directly to S3 using `uploadUrl`.

4. Client saves KYC metadata.

```http
POST /api/kyc/upload
Authorization: Bearer <token>
```

```json
{
  "documentType": "AADHAAR",
  "privateStorageKey": "kyc/driver/aadhaar.png",
  "maskedDocumentNumber": "****1234"
}
```

5. Backend stores only:

```text
private_storage_key
masked_document_number
status = PENDING
```

6. Admin views pending KYC.

```http
GET /api/admin/kyc/pending
Authorization: Bearer <admin-token>
```

7. Admin approves or rejects document.

```http
POST /api/admin/kyc/{id}/approve
POST /api/admin/kyc/{id}/reject
```

8. Important distinction:

```text
KycDocument approval = individual file/document approval
Rider/Driver profile approval = account eligibility approval
```

For drivers, final operational approval still uses:

```http
POST /api/admin/approve-driver-verification?driverId=<driverId>
```

## 6. Ride Booking Flow

This is the main rider-driver ride lifecycle.

1. Rider logs in and has active approved profile.

2. Driver logs in, is approved, and goes online.

```http
PUT /api/drivers/availability
```

```json
{
  "available": true,
  "online": true
}
```

3. Driver sends live location.

```http
PUT /api/drivers/location
```

```json
{
  "latitude": 28.6139,
  "longitude": 77.209
}
```

4. Rider estimates fare.

```http
POST /api/rides/estimate
```

```json
{
  "vehicleType": "SCOOTY",
  "pickupLat": 28.6139,
  "pickupLng": 77.209,
  "dropLat": 28.5355,
  "dropLng": 77.391
}
```

5. Rider books ride.

```http
POST /api/rides/book
```

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

6. Backend creates ride:

```text
ride.status = REQUESTED
ride.rider_id = rider_profile.id
ride.vehicle_type = SCOOTY/BIKE
```

7. Driver accepts ride.

```http
POST /api/rides/{rideId}/accept
Authorization: Bearer <driver-token>
```

8. Backend updates:

```text
ride.status = ACCEPTED
ride.driver_id = driver_profile.id
ride.vehicle_id = vehicle.id
ride.vehicle_registration_snapshot = current vehicle registration
ride.vehicle_model_snapshot = current vehicle model
ride.accepted_at = now
```

9. Rider gets safe driver details.

```text
driver full name
driver contact number
driver profile photo URL if available
vehicle type
vehicle registration
vehicle model
ETA
```

10. Driver gets safe rider ride details.

```text
rider full name
rider contact number
pickup/drop address
pickup/drop coordinates
guardian mode status
```

No Aadhaar, KYC documents, encrypted fields, or home/profile addresses are shared.

## 7. Ride Arrival And OTP Start Flow

Ride cannot start directly after accept.

1. Driver reaches pickup.

```http
POST /api/rides/{rideId}/arrive
Authorization: Bearer <driver-token>
```

2. Backend validates assigned driver.

3. Backend updates:

```text
ride.status = DRIVER_REACHED
ride.driver_reached_at = now
startOtp generated
startOtp hash stored
startOtpExpiresAt set
startOtpRetryCount reset
```

4. Rider fetches ride details.

```http
GET /api/rides/{rideId}
Authorization: Bearer <rider-token>
```

5. Rider app shows `startOtp`.

6. Rider shares OTP with driver.

7. Driver starts ride.

```http
POST /api/rides/{rideId}/start
Authorization: Bearer <driver-token>
```

```json
{
  "otp": "1234"
}
```

8. Backend validates:

```text
driver is assigned driver
ride status is DRIVER_REACHED
OTP is not expired
retry count is below max
OTP matches stored hash
```

9. If correct:

```text
ride.status = STARTED
ride.started_at = now
guardian mode/live tracking can start
```

10. If wrong:

```text
request rejected
retry count increases
ride remains DRIVER_REACHED
```

## 8. Ride Completion And Rating Flow

1. Driver completes ride.

```http
POST /api/rides/{rideId}/complete
Authorization: Bearer <driver-token>
```

2. Backend updates:

```text
ride.status = COMPLETED
ride.completed_at = now
driver completed rides count can update
safety score can update
earnings/payment can be calculated
```

3. Rider rates driver.

```http
POST /api/ratings
Authorization: Bearer <rider-token>
```

```json
{
  "rideId": "ride-uuid",
  "ratedUserId": "driver-user-id",
  "overallRating": 5,
  "safetyRating": 5,
  "comfortRating": 5,
  "drivingBehaviorRating": 5,
  "comments": "Safe and comfortable ride"
}
```

4. Admin can review ratings/complaints later.

## 9. Guardian Mode Flow

1. Rider adds trusted contact.

```http
POST /api/guardians
Authorization: Bearer <rider-token>
```

```json
{
  "name": "Mother",
  "mobileNumber": "9876500001",
  "relationship": "Mother",
  "autoShareLateNight": true
}
```

2. Rider starts or books a ride.

3. Rider enables live location sharing.

```http
POST /api/rides/{rideId}/share-live-location
Authorization: Bearer <rider-token>
```

4. Backend marks guardian sharing for the ride.

5. During late-night rides, guardian mode can auto-enable.

6. Future safety engine can trigger:

```text
route deviation alert
unusual stop alert
driver too far from route alert
guardian notification
```

## 10. SOS Flow

SOS can be triggered before, during, or after a ride.

1. User triggers SOS.

```http
POST /api/sos/trigger
Authorization: Bearer <token>
```

```json
{
  "rideId": "ride-uuid-or-null",
  "latitude": 28.6139,
  "longitude": 77.209,
  "message": "Need help"
}
```

2. Backend creates `sos_alert`.

3. Admin/support monitors active SOS.

```http
GET /api/admin/sos/active
Authorization: Bearer <admin-token>
```

4. Admin resolves SOS.

```http
POST /api/sos/{id}/resolve
Authorization: Bearer <admin-token>
```

```json
{
  "notes": "Contacted guardian and support team."
}
```

## 11. Complaint Flow

1. Rider or driver raises complaint.

```http
POST /api/complaints
Authorization: Bearer <token>
```

```json
{
  "rideId": "ride-uuid",
  "category": "SAFETY",
  "description": "Unsafe behavior reported"
}
```

2. User views own complaints.

```http
GET /api/complaints/me
```

3. Admin views complaints.

```http
GET /api/admin/complaints
```

4. Admin resolves complaint.

```http
POST /api/admin/complaints/{id}/resolve
```

```json
{
  "resolution": "Reviewed and resolved"
}
```

## 12. Payment Flow

Current payment flow is MVP/future-online ready.

1. Initiate payment.

```http
POST /api/payments/initiate
```

```json
{
  "rideId": "ride-uuid",
  "amount": 120.00,
  "method": "CASH"
}
```

2. Confirm payment.

```http
POST /api/payments/confirm
```

```json
{
  "paymentId": "payment-uuid",
  "providerReference": "cash-collected"
}
```

3. User checks history.

```http
GET /api/payments/history
```

4. Refund if needed.

```http
POST /api/payments/refund
```

## 13. Subscription Flow

1. List plans.

```http
GET /api/subscriptions/plans
```

2. Purchase plan.

```http
POST /api/subscriptions/purchase
```

```json
{
  "planId": "subscription-plan-uuid"
}
```

3. View active subscriptions.

```http
GET /api/subscriptions/me
```

## 14. Child Ride Flow

1. Guardian books child ride.

```http
POST /api/child-rides/book
```

```json
{
  "childName": "Child Name",
  "scheduledAt": "2026-05-12T08:00:00Z"
}
```

2. Driver verifies pickup OTP.

```http
POST /api/child-rides/{id}/pickup-verify
```

```json
{
  "otp": "1234"
}
```

3. Driver verifies drop OTP.

```http
POST /api/child-rides/{id}/drop-verify
```

```json
{
  "otp": "5678"
}
```

4. Guardian checks history.

```http
GET /api/child-rides/history
```

## 15. Commute Flow

1. User creates office/college commute schedule.

```http
POST /api/commutes
```

2. User lists schedules.

```http
GET /api/commutes/me
```

3. User pauses schedule.

```http
POST /api/commutes/{id}/pause
```

4. User cancels schedule.

```http
POST /api/commutes/{id}/cancel
```

## 16. Women Delivery Future Flow

This is Phase 4 architecture support.

1. User creates delivery request.

```http
POST /api/deliveries
```

```json
{
  "category": "PHARMACY",
  "pickupAddress": "Store address",
  "dropAddress": "Customer address",
  "itemDescription": "Medicines"
}
```

2. User checks delivery requests.

```http
GET /api/deliveries/me
```

## 17. Admin Operations Flow

Typical admin sequence:

1. Login as admin.

```http
POST /api/auth/login
```

2. Check dashboard.

```http
GET /api/admin/dashboard
```

3. Review pending riders.

```http
GET /api/admin/minor-riders
GET /api/admin/pending-guardian-verifications
```

4. Approve riders.

```http
POST /api/admin/approve-rider-verification?riderId=<riderId>
```

5. Review pending drivers.

```http
GET /api/admin/pending-driver-kyc
```

6. Approve drivers.

```http
POST /api/admin/approve-driver-verification?driverId=<driverId>
```

7. Monitor rides and SOS.

```http
GET /api/admin/rides/active
GET /api/admin/sos/active
```

8. Resolve complaints.

```http
GET /api/admin/complaints
POST /api/admin/complaints/{id}/resolve
```

9. Suspend or block users if needed.

```http
POST /api/admin/users/{id}/suspend
POST /api/admin/users/{id}/block
```

## 18. Live Location WebSocket Flow

1. Client connects to:

```text
/ws/location
```

2. Client sends live location message to:

```text
/app/location/update
```

3. Backend stores location through `LocationService`.

4. Subscribers receive updates from:

```text
/topic/rides/location
```

5. Redis should be used for live driver/ride location and temporary tracking sessions.

## 19. Full Happy Path For Manual Testing

Use this sequence to test the main SheGo product:

1. Start dependencies.

```bash
make deps
```

2. Start backend.

```bash
make backend
```

3. Login admin and save `adminToken`.

4. Create rider with `/api/riders/signup`; save `riderToken`.

5. Get rider profile with `/api/riders/profile`; save `riderId`.

6. Approve rider:

```http
POST /api/admin/approve-rider-verification?riderId=<riderId>
```

7. Create driver with `/api/drivers/signup`; save `driverToken`.

8. Get driver profile with `/api/drivers/profile`; save `driverId`.

9. Approve driver:

```http
POST /api/admin/approve-driver-verification?driverId=<driverId>
```

10. Driver goes online:

```http
PUT /api/drivers/availability
```

11. Driver updates location:

```http
PUT /api/drivers/location
```

12. Rider books ride:

```http
POST /api/rides/book
```

13. Driver accepts:

```http
POST /api/rides/{rideId}/accept
```

14. Driver marks arrival:

```http
POST /api/rides/{rideId}/arrive
```

15. Rider fetches ride details and sees OTP:

```http
GET /api/rides/{rideId}
```

16. Driver starts ride with OTP:

```http
POST /api/rides/{rideId}/start
```

17. Driver completes ride:

```http
POST /api/rides/{rideId}/complete
```

18. Rider rates driver:

```http
POST /api/ratings
```

This is the core production flow for the current MVP.

## 20. Debugging Flow

If an API fails:

1. Check HTTP status.

```text
400 = validation/business issue
401 = login/JWT problem
403 = role/authorization problem
500 = unexpected backend exception
```

2. Check backend logs. `GlobalExceptionHandler` logs full stack trace for unexpected errors.

3. For admin issues, verify:

```sql
select u.id, u.mobile_number, u.account_status, r.roles
from users u
join user_roles r on r.user_id = u.id
where u.mobile_number = '9999999999';
```

4. For pending driver issues, verify:

```sql
select dp.id, dp.user_id, dp.kyc_status, dp.admin_approval_status, dp.admin_approved
from driver_profile dp;

select id, driver_id, vehicle_type, registration_number, active
from vehicle;
```

5. Pending driver API should return any driver where:

```text
kyc_status = PENDING
OR admin_approval_status = PENDING
OR admin_approved = false
```
