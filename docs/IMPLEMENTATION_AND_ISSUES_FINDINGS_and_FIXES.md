# SheGo Daily Implementation & Issues Report

Date: May 11, 2026  
Timezone: Asia/Tokyo  
Project: SheGo women-first ride booking platform

## 1. Project Overview

SheGo is a women-focused urban ride booking platform for India. The current implementation is an MVP-oriented but production-aware architecture with a Spring Boot backend, Flutter frontend, PostgreSQL database, Redis temporary storage, AWS S3 file storage design, and Playwright API/E2E test automation.

### Architecture Summary

| Layer | Technology | Purpose |
|---|---|---|
| Backend | Java, Spring Boot 3, Spring Security | REST APIs, business rules, auth, ride workflows |
| Frontend | Flutter | Rider, Driver, and Admin UI flows |
| Database | PostgreSQL | Permanent business data |
| Cache/Temporary State | Redis | OTPs, retry counters, live location, temporary sessions |
| File Storage | AWS S3 | Aadhaar, license, insurance, selfie, profile images as private objects |
| API Docs | springdoc-openapi / Swagger UI | API discovery and JWT testing |
| Tests | Playwright + TypeScript | API and E2E ride flow automation |

### User Flows

- Rider signs up or logs in, completes eligibility/KYC requirements, books rides, sees driver details, shares OTP, tracks ride, pays, and rates.
- Driver signs up, uploads KYC/vehicle information, waits for admin approval, goes online, accepts rides, marks pickup arrival, enters OTP, starts and completes ride.
- Admin logs in with JWT, reviews riders/drivers/KYC, approves/rejects, monitors active rides and SOS alerts.

Vehicle support remains limited to:

```text
SCOOTY
BIKE
```

No auto, car, taxi, or mixed-gender ride support is part of the current implementation.

## 2. Issues Faced Today

| Issue | Symptoms | Root Cause | Fix Implemented | Files/Modules |
|---|---|---|---|---|
| Swagger JWT authorize button missing | Swagger UI did not show global Authorize button | OpenAPI security scheme was missing/incomplete | Added JWT bearer security scheme and whitelisted Swagger endpoints | `OpenApiConfig`, `SecurityConfig` |
| Admin APIs returned 403 after login | Admin login succeeded, but `/api/admin/**` returned 403 | Spring Security authority format did not match configured role checks | Loaded roles from `user_roles`, converted to `ROLE_ADMIN`, aligned with `hasRole("ADMIN")` | `User`, `UserRepository`, JWT auth filter, `SecurityConfig` |
| Admin API returned 500 instead of useful error | Response was `Unexpected server error` | Unhandled exceptions and `Optional.orElseThrow()` without domain exception | Added full stack logging and `BusinessException` handling with status codes | `GlobalExceptionHandler`, services |
| Pending drivers not appearing in Admin UI/API | Driver existed in `driver_profile`, but pending list was empty | Query did not reliably join `users`, `driver_profile`, and `vehicle` | Added pending driver query using `driver_profile.user_id = users.id` and left join vehicle | `DriverProfileRepository`, `AdminService` |
| Driver approval failed | Approve button showed `Unexpected server error` | UI called a generic/wrong approval path; KYC document approval and driver approval were confused | Admin UI now calls `POST /api/admin/drivers/{driverId}/approve`; backend updates driver approval safely | `AdminController`, `AdminService`, Flutter Admin UI |
| Rider approval failed | Adult female rider with `SELF_AADHAAR` caused 500 | Approval flow touched entity/mapping paths that could fail with null guardian data or sensitive fields | Added native, null-safe rider approval path that updates only `rider_profile` and linked `users` | `AdminService`, `RiderProfileRepository`, `UserRepository` |
| Wrong ID used | Confusion between `users.id`, `rider_profile.id`, `driver_profile.id`, and `kyc_document.id` | Different APIs require different entity IDs | Documented ID usage and fixed approval APIs to expect profile/document IDs correctly | Docs, Admin/KYC APIs |
| Driver signup OpenAPI test failed | Test claimed driver schema contained rider/guardian fields | Test inspected all OpenAPI schemas, including rider signup schema | Updated test to inspect only `/api/drivers/signup` request schema | `tests/api/driver-signup.spec.ts` |
| Driver signup used rider-specific fields earlier | Swagger/request shape showed guardian/rider Aadhaar fields under driver signup | DTO separation was incomplete | Driver signup uses `aadhaarNumber`; rider guardian fields remain rider-only | Driver DTOs and validation |
| Null pointer / missing row risks in approval | Local/dev records may not have all KYC rows | Approval flows assumed optional rows exist | Added null-safe handling and domain-specific errors | Admin/KYC services |
| Vehicle join issues | Pending driver response lacked vehicle data or could crash if vehicle values were null | Query/mapping did not handle optional active vehicle consistently | Left join active vehicle and null-safe DTO mapping | `DriverProfileRepository`, `AdminDtos` |
| UI layout broken on web | Role selection buttons stretched full width; eligibility text huge | Role selection used full-width `ListView` and inherited bad text styling | Added centered max-width responsive layout, small helper footer, card actions | `shego_flutter/lib/main.dart` |
| Login success but no navigation | Rider/Driver login showed success message but stayed on login screen | Post-login route handling was missing | Added role-based navigation to RiderHome, DriverHome, AdminDashboard | Flutter auth/navigation |
| Admin page opened without login | Admin tab/dashboard could be opened directly | Admin UI did not enforce local token state | Added AdminLoginScreen and token-gated AdminScreen | Flutter Admin UI |
| Incorrect login success message | Typo/wrong text such as `Cuthenticated...` | Stale UI message | Added role-specific login messages | Flutter login forms |
| Password reset architecture missing | Users/admin could not reset local passwords | Forgot password endpoints were not implemented | Added OTP send/verify/reset APIs and dev-only emergency reset endpoint | Auth/dev modules |
| OTP architecture discussion | Needed OTP storage without permanent DB state | OTPs should be temporary only | Designed Redis-backed OTP with expiry, retry, resend limits, dev OTP visibility only in local/dev | Auth service |
| Playwright tests skipped | E2E test showed `1 skipped` | `ADMIN_MOBILE` and `ADMIN_PASSWORD` were not loaded when running from nested folders | Added stable `.env` loading and fallback env parser | `tests/playwright.config.ts`, `tests/utils/flow.ts` |
| Playwright invalid URL | API tests failed with `Invalid URL` | Relative URLs need a Playwright `baseURL`, which was not always loaded depending on cwd | Added `apiUrl()` helper to build full URLs from `BASE_URL` | Test clients |
| Playwright localhost issue | Connection tried `::1:8080` | Node resolved `localhost` to IPv6 | Normalized `localhost` to `127.0.0.1` in test API URL helper | `tests/clients/authClient.ts` |
| TypeScript env/process typing issue | TS compile needed Node types/config | Test project needed local TS config and dependencies | Added/validated `tests/tsconfig.json`, `@types/node`, Playwright setup | `tests` |
| Missing root/test tsconfig clarity | Running TS checks from different folders caused confusion | Root and tests package structure differed | Verified `cd tests && npx tsc --noEmit` as the supported command | Test docs/config |
| KYC approve returned 500 | `POST /api/admin/kyc/{id}/approve` returned `Unexpected server error` | `documents.findById(id).orElseThrow()` threw `NoSuchElementException` | Added 404 `KYC document not found`, logs, null-safe linked profile updates | `KycService`, `KycController` |

## 3. Database Findings

PostgreSQL is the source of truth for all permanent business data. Redis is temporary only, and S3 stores uploaded binary files using private object keys.

### Important Tables

| Table | Purpose |
|---|---|
| `users` | Login identity, mobile/email, password hash, account status |
| `user_roles` | Role mapping for `RIDER`, `DRIVER`, `ADMIN`, `SUPPORT` |
| `rider_profile` | Rider-specific data, age, gender, KYC status, guardian fields |
| `driver_profile` | Driver-specific data, KYC/admin approval, availability, vehicle snapshots |
| `vehicle` | Driver vehicle record; only `SCOOTY` and `BIKE` |
| `kyc_document` | KYC document metadata and private S3 object key references |

### ID Rules

| ID | Source Table | Used By |
|---|---|---|
| `users.id` | `users` | Login identity, role ownership, token subject |
| `rider_profile.id` | `rider_profile` | Rider approval API |
| `driver_profile.id` | `driver_profile` | Driver approval API, driver ride assignment |
| `kyc_document.id` | `kyc_document` | KYC document approve/reject API |
| `vehicle.id` | `vehicle` | Ride vehicle reference |

Do not pass `users.id` into APIs that expect profile IDs.

### Key Relationships

```sql
rider_profile.user_id = users.id
driver_profile.user_id = users.id
vehicle.driver_id = driver_profile.id
kyc_document.user_id = users.id
ride.rider_id = rider_profile.id
ride.driver_id = driver_profile.id
ride.vehicle_id = vehicle.id
```

### Useful SQL Queries

Find rider profile ID from mobile number:

```sql
select
  rp.id as rider_id,
  rp.user_id,
  u.full_name,
  u.mobile_number,
  rp.rider_age,
  rp.rider_gender,
  rp.verification_type,
  rp.kyc_status,
  u.account_status
from rider_profile rp
join users u on rp.user_id = u.id
where u.mobile_number = '9999999999';
```

Find driver profile and vehicle:

```sql
select
  dp.id as driver_id,
  dp.user_id,
  u.full_name,
  u.mobile_number,
  dp.kyc_status,
  dp.admin_approval_status,
  dp.admin_approved,
  v.id as vehicle_id,
  v.vehicle_type,
  v.registration_number
from driver_profile dp
join users u on dp.user_id = u.id
left join vehicle v on v.driver_id = dp.id and v.active = true
where u.mobile_number = '9999999999';
```

Find pending drivers:

```sql
select
  dp.id as driver_id,
  u.id as user_id,
  u.full_name,
  u.mobile_number,
  dp.kyc_status,
  dp.admin_approval_status,
  dp.admin_approved,
  v.vehicle_type,
  v.registration_number
from driver_profile dp
join users u on dp.user_id = u.id
left join vehicle v on v.driver_id = dp.id and v.active = true
where dp.kyc_status = 'PENDING'
   or dp.admin_approval_status = 'PENDING'
   or dp.admin_approved = false;
```

Find KYC document ID:

```sql
select
  kd.id as kyc_document_id,
  kd.user_id,
  u.mobile_number,
  kd.document_type,
  kd.status,
  kd.private_storage_key
from kyc_document kd
join users u on kd.user_id = u.id
where u.mobile_number = '9999999999';
```

## 4. Backend Fixes Implemented

### DTO Changes

- Driver signup uses `aadhaarNumber`, not rider fields.
- Added safe admin approval response DTOs:
  - `RiderApprovalResponse`
  - `DriverApprovalResponse`
- Pending driver response includes only admin-safe fields.
- Ride participant response avoids Aadhaar/KYC/private address leakage.

### Service Changes

- Admin rider approval now uses a null-safe update path:

```text
rider_profile.kyc_status = APPROVED
users.account_status = ACTIVE
```

- Driver approval updates:

```text
driver_profile.kyc_status = APPROVED
driver_profile.admin_approval_status = APPROVED
driver_profile.admin_approved = true
driver_profile.available = false
driver_profile.online = false
users.account_status = ACTIVE
```

- KYC document approval now returns 404 when the document ID is invalid.
- Ride participant profile photo pre-signing no longer crashes ride details in local/dev when AWS is unavailable.

### Controller Changes

Fixed or added:

```http
GET  /api/admin/pending-driver-kyc
POST /api/admin/drivers/{driverId}/approve
POST /api/admin/approve-rider-verification?riderId={riderProfileId}
POST /api/admin/kyc/{kycDocumentId}/approve
POST /api/admin/kyc/{kycDocumentId}/reject
POST /api/auth/forgot-password/send-otp
POST /api/auth/forgot-password/verify-otp
POST /api/auth/forgot-password/reset
POST /api/dev/users/reset-password
POST /api/rides/{rideId}/arrive
POST /api/rides/{rideId}/start
```

### Repository Fixes

- Added driver pending query with `users` join and active vehicle left join.
- Added rider approval row lookup using native SQL to avoid optional guardian/sensitive field problems.
- Added direct status update methods for rider approval.
- Added user activation repository method.

### Swagger Security

Swagger/OpenAPI now supports JWT bearer auth:

```text
Authorization: Bearer <jwt-token>
```

Swagger endpoints remain public:

```text
/swagger-ui/**
/swagger-ui.html
/v3/api-docs/**
```

Admin APIs remain protected:

```text
/api/admin/**
```

### Admin Bootstrap

Local/dev admin bootstrap reads:

```text
ADMIN_FULL_NAME
ADMIN_MOBILE
ADMIN_EMAIL
ADMIN_PASSWORD
```

If no `ADMIN` user exists, a default admin is created with BCrypt password hash and `ACTIVE` status.

### OTP Design

OTP values are temporary and Redis-backed:

```text
forgot-password:{identifier}:otp
forgot-password:{identifier}:verified
ride:start-otp:{rideId}
```

Local/dev may expose or log OTP for testing. Production must use SMS provider integration and never return OTP in API responses.

## 5. Frontend/UI Fixes

### Admin UI

- Added `AdminLoginScreen`.
- Admin dashboard is protected behind token check.
- Pending driver list fetches `GET /api/admin/pending-driver-kyc`.
- Approve button calls:

```http
POST /api/admin/drivers/{driverId}/approve
```

- Reject button calls reject endpoint and refreshes list.

### Role-Based Navigation

After login:

| Role | Destination |
---|---|
| `ADMIN` | Admin dashboard |
| `RIDER` | Rider home |
| `DRIVER` | Driver home |

JWT is persisted with Flutter secure storage and restored on app launch.

### Rider UI

Added/connected screens for:

- Rider login/signup
- Rider home
- Book ride
- Fare estimate
- Searching driver
- Driver details
- Ride OTP
- Active ride tracking placeholder
- Payment screen
- Rating/review
- Ride history
- Guardian contacts
- SOS

### Driver UI

Added/connected screens for:

- Driver login/signup
- Driver home
- KYC status
- Availability
- Ride request
- Rider details
- Navigate to pickup
- Pickup arrived
- Enter OTP
- Active ride
- Complete ride
- Earnings
- Ride history
- Profile

### Responsive UI Fix

The welcome/role selection screen was updated to:

- Center content.
- Use a max-width container around 480px.
- Avoid full-width desktop buttons.
- Keep logo centered.
- Use a card for action buttons.
- Use small helper text for eligibility note.
- Use `SingleChildScrollView` for short screens.

## 6. Security Improvements

| Area | Improvement |
|---|---|
| JWT | Bearer token auth configured for app and Swagger |
| Admin APIs | Protected with role-based access |
| Roles | Loaded from `user_roles` and mapped to Spring authorities |
| Passwords | BCrypt hashing for signup, admin bootstrap, and reset |
| OTP | Redis-backed temporary storage with expiry/retry design |
| KYC | Full Aadhaar not returned in API responses |
| S3 | PostgreSQL stores private object keys, not public URLs |
| API Responses | Approval/list responses avoid encrypted/sensitive fields |
| Dev Reset | `/api/dev/users/reset-password` enabled only in local/dev profile |
| UI | Admin dashboard does not open without token |

### Privacy Rules Preserved

- Rider does not receive driver home/profile address.
- Driver does not receive rider home/profile address.
- Only pickup/drop addresses are shared for rides.
- Aadhaar encrypted values are not exposed.
- KYC document URLs are not exposed in list APIs.
- Temporary profile photo access uses pre-signed URLs when available.

## 7. Playwright Testing

### Setup

```bash
cd tests
npm install
npx playwright test
```

Environment:

```env
BASE_URL=http://localhost:8080
ADMIN_MOBILE=9999999999
ADMIN_PASSWORD=your_admin_password
```

### Test Structure

```text
tests/
├── api/
├── e2e/
├── clients/
├── fixtures/
├── utils/
└── playwright.config.ts
```

### Fixes Made

| Problem | Fix |
|---|---|
| Tests skipped | Stable `.env` loading plus fallback parser |
| Invalid URL | Added `apiUrl()` helper |
| IPv6 localhost issue | Normalized `localhost` to `127.0.0.1` |
| TypeScript process/env typing | Validated `tests/tsconfig.json` and Node types |
| OpenAPI schema false failure | Checked only `/api/drivers/signup` schema |

Supported validation command:

```bash
cd tests
npx tsc --noEmit
```

### Planned E2E Coverage

```text
admin login
create rider
create driver
approve rider
approve driver
driver goes online
rider books ride
driver accepts
driver marks arrival
rider sees OTP
driver starts ride with OTP
driver completes ride
rider rates driver
```

## 8. APIs Added or Fixed

| API | Method | Purpose | Status |
|---|---:|---|---|
| `/api/auth/login` | POST | Login and receive JWT | Fixed/verified |
| `/api/auth/forgot-password/send-otp` | POST | Send/simulate password reset OTP | Added |
| `/api/auth/forgot-password/verify-otp` | POST | Verify reset OTP | Added |
| `/api/auth/forgot-password/reset` | POST | Reset password with OTP | Added |
| `/api/dev/users/reset-password` | POST | Local/dev emergency password reset | Added |
| `/api/admin/dashboard` | GET | Admin dashboard summary | Protected |
| `/api/admin/pending-driver-kyc` | GET | Pending driver verification list | Fixed |
| `/api/admin/drivers/{driverId}/approve` | POST | Approve driver profile | Fixed |
| `/api/admin/approve-rider-verification?riderId=` | POST | Approve rider profile | Fixed |
| `/api/admin/kyc/{id}/approve` | POST | Approve KYC document | Fixed |
| `/api/admin/kyc/{id}/reject` | POST | Reject KYC document | Fixed |
| `/api/riders/signup` | POST | Rider signup with eligibility rules | Implemented |
| `/api/riders/login` | POST | Rider login | Implemented |
| `/api/drivers/signup` | POST | Driver signup with women-only rules | Fixed/implemented |
| `/api/drivers/login` | POST | Driver login | Implemented |
| `/api/drivers/availability` | PUT | Driver online/offline state | Implemented |
| `/api/rides/book` | POST | Book ride | Implemented |
| `/api/rides/{rideId}/accept` | POST | Driver accepts ride | Fixed/implemented |
| `/api/rides/{rideId}/arrive` | POST | Driver reached pickup and OTP generated | Added |
| `/api/rides/{rideId}/start` | POST | OTP-based ride start | Added |
| `/api/rides/{rideId}/complete` | POST | Complete ride | Implemented |
| `/api/ratings` | POST | Submit ride rating | Implemented |

## 9. Remaining TODO Items

Production hardening still required:

- Real SMS provider integration for OTP.
- Production OTP masking and audit policy.
- Payment gateway integration.
- Refund lifecycle.
- Google Maps live route drawing.
- ETA and route deviation engine.
- Real push notifications.
- WebSocket client integration in Flutter for live ride requests.
- Driver matching optimization using geo queries.
- S3 IAM policy hardening.
- Full KYC aggregate approval rules.
- Admin audit log visibility.
- CI/CD pipeline.
- Automated database migration checks.
- Play Store signing, privacy policy, and release workflow.
- Production observability with CloudWatch dashboards/alarms.

### KYC Production Rule Still Needed

Current KYC document approval is MVP-friendly. Real production should approve profile KYC only after all required documents pass.

Suggested production aggregate logic:

```text
Adult female rider:
  SELF_AADHAAR approved -> rider_profile.kyc_status = APPROVED

Minor rider / male child rider:
  GUARDIAN_AADHAAR approved
  guardian consent verified
  -> rider_profile.kyc_status = APPROVED

Driver:
  AADHAAR approved
  DRIVING_LICENSE approved
  VEHICLE_DOCUMENT approved
  INSURANCE approved
  SELFIE approved
  admin approval approved
  -> driver can go online
```

## 10. Lessons Learned

### Profile ID vs User ID

Many approval APIs should not use `users.id`. They need profile or document IDs:

```text
Rider approval -> rider_profile.id
Driver approval -> driver_profile.id
KYC approval    -> kyc_document.id
Login/token     -> users identity
```

### Null-Safe Backend Design

Local/dev data often lacks full KYC or guardian rows. Approval and admin list flows must handle missing optional records without returning HTTP 500.

### Response Wrapper Parsing

Backend uses:

```json
{
  "success": true,
  "message": "...",
  "data": {}
}
```

Flutter and tests should consistently parse `data`.

### Role-Based Navigation

Frontend must route using backend roles, not hardcoded UI assumptions.

### Local/Dev Architecture

Local/dev should simulate external services safely:

- OTP in Redis, optionally visible only in local/dev.
- S3 URL failure should not break optional profile photo display.
- Dev reset endpoint must never run in production.

### MVP-First Strategy

The MVP can approve flows manually and use placeholders for SMS/payment/maps, but production rules must be documented and isolated so they can be hardened without rewriting modules.

## 11. Final Status Summary

### Fully Working or Verified

- Spring Boot compile/tests.
- JWT auth and role-based admin access.
- Swagger JWT Authorize configuration.
- Default admin bootstrap from environment.
- Admin pending driver listing.
- Driver approval endpoint using `driver_profile.id`.
- Rider approval endpoint using `rider_profile.id`.
- KYC document approval/reject 404-safe handling.
- Flutter role selection responsive layout.
- Flutter login routes for Admin/Rider/Driver.
- Flutter secure token persistence.
- TypeScript compilation for tests.

### Partially Working

- Flutter Rider/Driver flows are connected but still MVP-level.
- Ride flow is API-backed, but WebSocket/push matching is not fully wired into Flutter UI.
- Payment is cash-first UI with backend integration placeholders for provider flow.
- S3 pre-signed profile URLs are supported but local/dev may return null if AWS is unavailable.
- KYC approval works but aggregate production rules are still simplified.

### Still Needs Implementation

- Real SMS OTP.
- Real payment gateway.
- Full driver matching and dispatch.
- Live map and WebSocket client UI.
- Production-grade KYC aggregate verification.
- Complete admin dashboard UI for every operational module.
- CI/CD and AWS production deployment automation.
- Play Store release preparation and compliance checklist.

## Appendix: Important API Examples

### Admin Login

```http
POST /api/auth/login
Content-Type: application/json

{
  "mobileNumber": "9999999999",
  "password": "Admin1234"
}
```

### Approve Rider

Use `rider_profile.id`.

```http
POST /api/admin/approve-rider-verification?riderId=<rider_profile_id>
Authorization: Bearer <admin_jwt>
```

### Approve Driver

Use `driver_profile.id`.

```http
POST /api/admin/drivers/<driver_profile_id>/approve
Authorization: Bearer <admin_jwt>
```

### Approve KYC Document

Use `kyc_document.id`.

```http
POST /api/admin/kyc/<kyc_document_id>/approve
Authorization: Bearer <admin_jwt>
```

### Ride Start With OTP

```http
POST /api/rides/<ride_id>/start
Authorization: Bearer <driver_jwt>
Content-Type: application/json

{
  "otp": "1234"
}
```
