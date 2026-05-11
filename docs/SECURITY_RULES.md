# SheGo Security Rules

This document describes security rules that must be followed by current and future SheGo backend work.

## Authentication

SheGo uses Spring Security with stateless JWT authentication.

Current public routes are:

- `/api/auth/**`
- `/api/riders/signup`
- `/api/riders/login`
- `/api/drivers/signup`
- `/api/drivers/login`
- `/v3/api-docs/**`
- `/swagger-ui/**`
- `/swagger-ui.html`
- `/ws/**`

All other routes require JWT authentication unless explicitly changed in `SecurityConfig`.

## Authorization

- `/api/admin/**` requires `ADMIN` or `SUPPORT`.
- Admin-only file download intents use `@PreAuthorize("hasAnyRole('ADMIN','SUPPORT')")`.
- Rider profile APIs must operate on the authenticated rider.
- Driver profile, availability, location, and KYC APIs must operate on the authenticated driver.
- Driver online/availability changes are blocked until KYC and admin approval are complete.

## Password and OTP Rules

- Passwords are hashed with BCrypt.
- OTP values are generated server-side and stored in Redis as BCrypt hashes.
- OTP values expire after 5 minutes.
- OTP retry/rate keys expire after 10 minutes.
- Do not log OTP values in production.
- Do not store OTP values in PostgreSQL.

## Aadhaar Security

Full Aadhaar can be accepted by API requests during KYC/signup, but must not be exposed afterward.

Current storage rule:

- encrypt full Aadhaar with `SensitiveStringConverter`
- store only encrypted Aadhaar in PostgreSQL
- store only last 4 digits separately for display
- never return full Aadhaar in API responses
- never show full Aadhaar in admin UI
- never log full Aadhaar
- never store Aadhaar in Redis

The encryption key is configured with:

- `SHEGO_DATA_ENCRYPTION_KEY`

Production must use a strong secret from AWS Secrets Manager or SSM Parameter Store.

## S3 File Security

Uploaded files must go to private AWS S3 paths only. Supported uploads include:

- Aadhaar image
- driving license image
- vehicle document image
- insurance image
- selfie verification image
- profile photo

Rules:

- PostgreSQL stores only object keys.
- No raw file bytes in PostgreSQL.
- No public S3 URLs in PostgreSQL.
- Uploads use short-lived pre-signed PUT URLs from `/api/storage/upload-intent`.
- Admin/support downloads use short-lived pre-signed GET URLs from `/api/storage/download-intent`.
- Download intent access must remain admin/support-only.

## Redis Security Boundary

Redis is temporary-only storage:

- OTP codes and retry counters
- temporary login/session cache
- live driver location
- live ride location
- temporary guardian tracking session

Do not store permanent signup, KYC, ride, payment, complaint, subscription, or audit data in Redis.

## Vehicle and Ride Security Rules

- Vehicle type is restricted to `SCOOTY` and `BIKE`.
- Database check constraints enforce this on vehicle, ride, driver profile, and commute schedule tables.
- Only verified, active, admin-approved women drivers can accept rides.
- Driver cannot accept multiple active rides.
- Only the assigned driver can mark pickup arrival.
- Only the assigned driver can submit the ride start OTP.
- Ride start requires OTP verification after `DRIVER_REACHED`.
- Ride start OTP hashes are stored in PostgreSQL; temporary rider-visible OTP values live in Redis only until expiry.
- OTP retry count and expiry must be enforced before setting ride status to `STARTED`.
- Ride records must keep rider, driver, vehicle, status, snapshots, and timestamps for auditability.

## Ride Participant Privacy

Rider and driver apps receive only operational ride data:

- names and contact numbers needed for pickup coordination
- temporary profile photo URL when available
- pickup/drop addresses and coordinates
- vehicle details for the accepted ride
- ride status and ETA

Do not expose:

- Aadhaar numbers
- encrypted fields
- KYC document object keys
- home/profile addresses
- raw files
- internal OTP hash values

## CORS and API Exposure

Current local CORS allows all origins through `allowedOriginPatterns("*")`. Before production release, restrict CORS to approved SheGo app/admin domains.

Swagger/OpenAPI routes are currently public for development. For production, either restrict them to internal networks/admin access or disable public Swagger exposure.

## Audit Logging

Admin actions such as user suspension/blocking and rider/driver verification approval must be recorded in `admin_action_log`.

Future admin operations that change user status, KYC status, driver approval, payments, refunds, complaints, or safety escalations must also write audit logs.

## Future Implementation Rule

Future code must follow these security rules before merge:

- no full Aadhaar in responses or logs
- no public S3 document URLs
- no raw files in PostgreSQL
- no permanent data in Redis
- admin/support checks on sensitive review/download APIs
- Flyway migrations for schema changes
- role checks on rider, driver, support, and admin APIs
