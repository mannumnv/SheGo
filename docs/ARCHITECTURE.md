# SheGo Architecture

This document describes the current implemented SheGo backend and is the source of truth for future backend changes.

## Product Boundary

SheGo is a women-first ride booking platform for India. Current ride support is only:

- `SCOOTY`
- `BIKE`

Do not add auto, car, taxi, or mixed-gender ride support unless the product rules are formally changed.

## Backend Stack

- Java/Spring Boot backend under `src/main/java/com/shego`
- Spring Security with JWT access/refresh tokens
- Spring Data JPA with PostgreSQL
- Flyway migrations under `src/main/resources/db/migration`
- Redis for temporary OTP/session/live-location data
- WebSocket/STOMP for live ride location
- AWS S3 pre-signed URL flow for private file upload/download
- OpenAPI/Swagger enabled through springdoc

## Current Package Structure

The backend is organized by business module:

- `auth`: registration, login, OTP, refresh token
- `user`: current user/profile access
- `rider`: rider signup, rider profile, guardian verification
- `driver`: driver signup, onboarding, availability, location, earnings
- `vehicle`: driver vehicle data
- `kyc`: KYC document metadata and admin approval/rejection
- `ride`: estimate, book, accept, start, complete, cancel, history
- `location`: ride location persistence and WebSocket live location
- `guardian`: guardian contacts, trusted drivers, live sharing
- `safety`: late-night policy, safety events, driver safety score
- `sos`: SOS trigger and admin resolution
- `childride`: child safe ride booking and OTP verification
- `subscription`: plans and user subscriptions
- `payment`: payment records and driver earnings
- `rating`: rider/driver ratings and unsafe reports
- `complaint`: support complaint workflow
- `notification`: notification records
- `admin`: admin dashboard, approvals, audit logs
- `storage`: S3 pre-signed upload/download intents
- `commute`: office/college/metro recurring commute schedules
- `delivery`: future women delivery network module
- `common`, `config`, `exception`: shared enums, security, responses, errors

## Data Stores

PostgreSQL is the primary database for permanent business data:

- users and roles
- rider and driver profiles
- vehicles
- rides and ride history
- KYC metadata and private S3 object keys
- guardian contacts and trusted drivers
- SOS, safety events, safety scores
- payments, subscriptions, ratings, complaints
- admin audit logs
- commute, child ride, delivery records

AWS S3 stores uploaded files only:

- Aadhaar image
- driving license image
- vehicle document image
- insurance image
- selfie verification image
- profile photo

PostgreSQL stores only private S3 object keys, never raw images/files and never public S3 URLs.

Redis is temporary only:

- OTP code hashes
- OTP retry counters
- temporary login/session cache
- live driver location
- live ride location
- temporary guardian tracking session

Do not place permanent signup, KYC, ride, payment, or audit data in Redis.

## Security Model

`SecurityConfig` currently permits public access only to:

- `/api/auth/**`
- `/api/riders/signup`
- `/api/riders/login`
- `/api/drivers/signup`
- `/api/drivers/login`
- `/v3/api-docs/**`
- `/swagger-ui/**`
- `/swagger-ui.html`
- `/ws/**`

Admin APIs under `/api/admin/**` require `ADMIN` or `SUPPORT`. All other API routes require JWT authentication.

## Ride Architecture

Each ride is a permanent PostgreSQL record. The `ride` table stores:

- `rider_id`
- `driver_id`
- `vehicle_id`
- `vehicle_type`
- vehicle registration snapshot
- vehicle model snapshot
- pickup/drop coordinates and addresses
- estimate/final fare
- start/completion OTP fields
- guardian and late-night flags
- ride status
- accepted, assigned, driver reached, rider boarded, started, completed, ride completed, and cancelled timestamps

When a driver accepts a ride, the service links the active driver vehicle and stores vehicle snapshots so ride history remains auditable even if the vehicle record changes later.

## Ride Participant Sharing

Ride participant data is shared only through safe DTOs in `RideDtos`.

Rider-facing ride details may include:

- driver full name
- driver contact number
- temporary driver profile photo URL when `profilePhotoStorageKey` exists
- vehicle type
- vehicle registration snapshot
- vehicle model snapshot
- ride status
- ETA
- pickup/drop details
- ride start OTP only after status becomes `DRIVER_REACHED`

Driver-facing ride details may include:

- rider full name
- rider contact number
- temporary rider profile photo URL when available
- pickup/drop addresses
- pickup/drop coordinates
- guardian mode flag
- ride status

The DTOs must not expose Aadhaar, encrypted fields, KYC document keys, user profile/home addresses, or admin-only data.

## OTP Ride Start Flow

Current implemented flow:

1. Rider books a ride and the backend creates `ride.status = REQUESTED`.
2. Driver accepts the ride and backend sets `driver_id`, `vehicle_id`, vehicle snapshots, `status = ACCEPTED`, and `accepted_at`.
3. Driver marks pickup arrival through `POST /api/rides/{rideId}/arrive`.
4. Backend sets `status = DRIVER_REACHED`, generates a 4-digit start OTP, stores a BCrypt hash in PostgreSQL, stores the temporary OTP in Redis for rider display, and sets expiry/retry fields.
5. Rider can load ride details and see the OTP only while the OTP is active.
6. Driver submits the OTP through `POST /api/rides/{rideId}/start`.
7. Backend verifies the OTP, retry count, assigned driver, and expiry.
8. On success, backend sets `status = STARTED`, saves `started_at`, and deletes the temporary Redis OTP.

## Future Implementation Rule

Any future feature must follow this architecture:

- permanent business data in PostgreSQL
- uploaded file bytes in private S3 only
- private S3 object keys in PostgreSQL
- temporary volatile data in Redis only
- vehicle support restricted to `SCOOTY` and `BIKE`
- no full Aadhaar exposure in API responses, logs, or UI
