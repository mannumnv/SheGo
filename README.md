# SheGo Backend

SheGo is a women-only ride booking backend for India, focused on verified female riders and drivers, scooty/bike rides, safety, guardian tracking, SOS, KYC, and admin approval.

## Architecture

- Backend: Java 21, Spring Boot 3, Spring Security, JWT, Spring Data JPA, PostgreSQL, Redis, WebSocket/STOMP, Flyway, Maven.
- Storage: KYC/profile files should be uploaded to private AWS S3 paths and referenced by `privateStorageKey`; files must never be public.
- Permanent data: PostgreSQL stores users, riders, drivers, vehicles, rides, KYC metadata, payments, subscriptions, complaints, audit logs, and private S3 object keys.
- Temporary data: Redis is only for OTPs/retry counters, short-lived session/cache data, live driver/ride location, and temporary guardian tracking sessions.
- Realtime: driver/rider live location uses `/ws/location`, app destination `/app/location/update`, topic `/topic/rides/location`.
- Deployment: Docker-ready for AWS EC2/ECS with RDS PostgreSQL, Redis/ElastiCache, S3, and CloudWatch.
- Frontend direction: Flutter for Rider and Driver apps; React for Admin dashboard.

## Current MVP Modules

- Auth with JWT/refresh token endpoints and BCrypt password hashing.
- Rider/driver registration, KYC upload, KYC approval, admin driver approval.
- Driver onboarding with `SCOOTY` and `BIKE` only.
- Driver availability, Redis-backed driver location, nearby driver search.
- Ride estimate/book/accept/reject/start/complete/cancel/history.
- OTP ride start, late-night guardian auto-enable, active ride checks.
- Guardian contacts and live location sharing switch.
- SOS trigger and admin resolution.
- Safety score service based on KYC, background verification, ratings, ride history, complaints, deviations, and incidents.
- Ratings, complaints, payments, subscriptions, child ride, notifications, admin dashboard, and audit logs.

## Local Setup

Required:

- Java 21 for the production backend build
- Maven 3.9+
- Docker Desktop for PostgreSQL and Redis
- Flutter 3.4+ for the app

Your local Maven must point to JDK 21. Check with:

```bash
mvn -version
```

If Maven still uses Java 17, install JDK 21 and set `JAVA_HOME`.

## Makefile Commands

Common workflows are available from the repository root:

```bash
make help
make deps
make backend
make frontend
make backend-build
make flutter-apk
```

## Test Automation

Playwright API/E2E automation lives in [tests/README.md](tests/README.md).

```bash
npm install
npx playwright test
npx playwright test tests/api
npx playwright test tests/e2e
npx playwright show-report
```

## Database and Redis

Start PostgreSQL and Redis:

```bash
docker compose up postgres redis
```

Default local values:

```text
DB_URL=jdbc:postgresql://localhost:5432/shego
DB_USERNAME=shego
DB_PASSWORD=shego
REDIS_HOST=localhost
REDIS_PORT=6379
```

Flyway migrations run automatically on backend startup.

## Backend Run Command

```bash
mvn spring-boot:run
```

Or run everything with Docker:

```bash
docker compose up --build
```

The API runs at `http://localhost:8080`.

## Flutter Run Command

```bash
cd shego_flutter
flutter pub get
flutter run -d chrome
```

The Flutter app calls `http://localhost:8080` by default.

## Environment Variables

```text
PORT=8080
DB_URL=jdbc:postgresql://localhost:5432/shego
DB_USERNAME=shego
DB_PASSWORD=shego
REDIS_HOST=localhost
REDIS_PORT=6379
JWT_SECRET=change-this-dev-secret-change-this-dev-secret
SHEGO_DATA_ENCRYPTION_KEY=change-this-32-byte-production-secret
ACCESS_TOKEN_MINUTES=30
REFRESH_TOKEN_DAYS=30
S3_BUCKET=shego-dev-private
GOOGLE_MAPS_API_KEY=
```

## Data Storage Rules

- Do not store raw uploaded files in PostgreSQL.
- Store only private S3 object keys for Aadhaar, license, vehicle documents, insurance, selfie verification, and profile photos.
- Admin/support access to files must use short-lived pre-signed download URLs from `/api/storage/download-intent`.
- Full Aadhaar values are encrypted before PostgreSQL persistence.
- Aadhaar last 4 digits are stored separately for masked display.
- Full Aadhaar must never be returned in API responses or admin UI.
- Permanent signup/KYC data must not be stored in Redis.

## Key API Examples

Rider signup:

```http
POST /api/riders/signup
Content-Type: application/json

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

Minor rider signup with guardian verification:

```http
POST /api/riders/signup
Content-Type: application/json

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

Driver signup:

```http
POST /api/drivers/signup
Content-Type: application/json

{
  "fullName": "Nisha Verma",
  "mobileNumber": "9876543220",
  "password": "secret123",
  "gender": "FEMALE",
  "dateOfBirth": "1998-02-10",
  "address": "Noida",
  "aadhaarNumber": "123412341234",
  "drivingLicenseNumber": "DL-0420110012345",
  "vehicleType": "SCOOTY",
  "vehicleRegistrationNumber": "DL01AB1234",
  "insuranceDetails": "INS-123"
}
```

Upload KYC:

```http
POST /api/kyc/upload
Authorization: Bearer <token>
Content-Type: application/json

{
  "documentType": "AADHAAR",
  "privateStorageKey": "kyc/9876543210/aadhaar-front.jpg",
  "maskedDocumentNumber": "XXXX-XXXX-1234"
}
```

Driver onboarding:

```http
POST /api/drivers/onboard
Authorization: Bearer <driver-token>
Content-Type: application/json

{
  "licenseNumber": "DL-0420110012345",
  "vehicleType": "SCOOTY",
  "vehicleRegistrationNumber": "DL01AB1234",
  "insurancePolicyNumber": "INS-123",
  "model": "Activa"
}
```

Book ride:

```http
POST /api/rides/book
Authorization: Bearer <rider-token>
Content-Type: application/json

{
  "vehicleType": "BIKE",
  "pickupLat": 28.6139,
  "pickupLng": 77.2090,
  "dropLat": 28.5355,
  "dropLng": 77.3910,
  "pickupAddress": "Connaught Place",
  "dropAddress": "Noida Sector 18"
}
```

Start ride:

Driver marks pickup arrival first:

```http
POST /api/rides/{rideId}/arrive
Authorization: Bearer <driver-token>
```

Rider loads ride details and sees `startOtp` only after `DRIVER_REACHED`:

```http
GET /api/rides/{rideId}
Authorization: Bearer <rider-token>
```

Driver starts ride with rider-shared OTP:

```http
POST /api/rides/{rideId}/start
Authorization: Bearer <driver-token>
Content-Type: application/json

{ "otp": "1234" }
```

Trigger SOS:

```http
POST /api/sos/trigger
Authorization: Bearer <token>
Content-Type: application/json

{
  "rideId": "00000000-0000-0000-0000-000000000000",
  "latitude": 28.6139,
  "longitude": 77.2090,
  "message": "Need help"
}
```

## API Testing Steps

1. Register a rider with `/api/riders/signup`.
2. Register a driver with `/api/drivers/signup`.
3. Upload KYC metadata with `/api/kyc/upload` or driver KYC with `/api/drivers/upload-kyc`.
4. Review minor riders with `/api/admin/minor-riders` and guardian approvals with `/api/admin/pending-guardian-verifications`.
5. Approve rider verification with `/api/admin/approve-rider-verification?riderId=<id>`.
6. Review driver KYC with `/api/admin/pending-driver-kyc`.
7. Approve driver verification with `/api/admin/approve-driver-verification?driverId=<id>`.
8. Set driver availability with `/api/drivers/availability`.
9. Estimate and book a `SCOOTY` or `BIKE` ride.
10. Accept, start with OTP, complete, and rate the ride.
11. Test guardian contact creation, SOS trigger, and WebSocket live location.
12. Test Phase 2/3/4 APIs: `/api/commutes`, `/api/child-rides/book`, `/api/subscriptions/plans`, `/api/deliveries`.

## Business Rules Implemented

- Current ride types are restricted to `SCOOTY` and `BIKE`.
- Riders can be female users of any age, boys below 14, or other-gender users pending admin review.
- Male riders age 14 or above are rejected during signup.
- Female riders under 18 and male riders under 14 require guardian Aadhaar and guardian consent.
- Adult female riders require self Aadhaar verification.
- Drivers must be adult women and cannot go online until KYC and admin approval are complete.
- Only approved riders can book.
- Only KYC-approved, active, admin-approved drivers can go online or accept rides.
- A driver cannot accept more than one active ride.
- Ride start requires OTP.
- Driver must mark arrival before ride start; only the assigned driver can submit the OTP.
- Ride start OTP hash is stored in PostgreSQL, while the temporary rider-visible OTP lives in Redis until expiry.
- Accepted ride details share only safe participant data: names, contact numbers, temporary profile photo URLs, vehicle details, pickup/drop, ETA, and ride status.
- Guardian mode auto-enables between 10 PM and 5 AM India time.
- SOS can be created with or without a ride.
- Safety score recalculates after ride completion.

## Roadmap

Phase 1 MVP:
Auth, registration, KYC, admin approval, availability, nearby search, ride lifecycle, WebSocket location, guardians, SOS, rating, admin dashboard.

Phase 2:
Late-night risk scoring, trusted drivers, complaint workflows, payments, refunds, invoices, driver earnings.

Phase 3:
Child safe ride, subscriptions, office/college commute passes, corporate transport, advanced route risk scoring.

Phase 4:
Women delivery network, wearable SOS, voice trigger, fraud detection, driver behavior telemetry, AI-assisted safety operations.

## Documentation

Future implementation must follow these project-specific docs:

- [Architecture](docs/ARCHITECTURE.md)
- [Database Rules](docs/DB_RULES.md)
- [KYC Rules](docs/KYC_RULES.md)
- [Security Rules](docs/SECURITY_RULES.md)
- [AWS Deployment Guide](docs/AWS_DEPLOYMENT_GUIDE.md)
- [Play Store and User Release Guide](docs/PLAYSTORE_AND_USER_RELEASE_GUIDE.md)

## AWS Deployment

See [docs/AWS_DEPLOYMENT_GUIDE.md](docs/AWS_DEPLOYMENT_GUIDE.md).

## Future Delivery Network Boundary

Delivery should be added as a new package such as `com.shego.delivery` with shared identity, KYC, payment, safety, and notification services. Do not add car/taxi/auto ride types to the ride module unless the product rules change.
