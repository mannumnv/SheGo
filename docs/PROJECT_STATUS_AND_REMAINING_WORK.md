# SheGo Project Status and Remaining Work

This document summarizes what has been completed for SheGo and what still needs to be implemented for real-world production use.

## Accomplished

### Backend Foundation

- Spring Boot backend created with Java 21 target.
- Maven project configured.
- Required package structure created under `com.shego`.
- PostgreSQL database schema managed with Flyway.
- Dockerfile and `docker-compose.yml` added.
- Redis included for OTP/session/live-location support.
- AWS deployment guide added.
- Makefile added for common run/test/build commands.

### Security and Auth

- JWT authentication implemented.
- Refresh token endpoint added.
- BCrypt password hashing implemented.
- Role-based authorization added for `RIDER`, `DRIVER`, `ADMIN`, and `SUPPORT`.
- Mobile OTP send/verify flow added with Redis-backed rate limiting.
- Global exception handling added.
- API response wrapper added.
- CORS configuration added.

### User, KYC, and Driver Verification

- Rider, driver, admin, and support user roles supported.
- User profile APIs added.
- KYC document metadata upload added.
- KYC status API added.
- Admin KYC approve/reject APIs added.
- S3 presigned upload intent API added for private KYC/profile/SOS files.
- Driver onboarding added.
- Driver vehicle details added.
- Vehicle types restricted to `SCOOTY` and `BIKE`.
- Admin driver approval added.
- Driver availability and online/offline status added.

### Ride Booking

- Fare estimate API added.
- Ride booking API added.
- Driver accept/reject APIs added.
- Ride start with OTP added.
- Ride complete/cancel APIs added.
- Ride history and ride detail APIs added.
- Driver active ride restriction added.
- Driver earnings generated after ride completion.
- Safety score recalculates after ride completion.

### Safety, Guardian, and SOS

- Guardian contact add/list/delete APIs added.
- Guardian live-location sharing API added.
- Late-night safety policy API added.
- Guardian mode auto-enables for late-night rides.
- SOS trigger API added.
- SOS admin active-list and resolve APIs added.
- Safety events API added.
- Driver safety score API added.
- Trusted driver add/list APIs added.
- Ride location WebSocket endpoint added.
- Ride location persistence and history API added.

### Phase 2, Phase 3, and Phase 4 Modules

- Complaint system added.
- Rating and review APIs added.
- Payment initiate/confirm/refund/history APIs added.
- Subscription plans and purchase APIs added.
- Child ride booking, pickup OTP, drop OTP, and history APIs added.
- Office/college/metro/school commute scheduling module added.
- Women delivery future module added.
- Notification records and ride notification hooks added.
- Basic admin dashboard APIs added.
- Rider/driver-specific signup and login APIs added.
- Rider eligibility validation added for female riders, boys below 14, and other-gender admin review.
- Driver eligibility validation added for adult verified women only.
- Guardian Aadhaar, self Aadhaar, rider age category, verification type, and driver approval fields added to schema.
- Admin verification monitoring APIs added for minor riders, guardian approvals, and driver KYC.
- Production storage/data boundary added: PostgreSQL stores permanent records and private S3 keys, S3 stores uploaded files, Redis remains temporary only.
- Aadhaar persistence updated to encrypted columns plus last-4 display fields; full Aadhaar is not returned in API responses.
- Ride now supports direct vehicle reference, vehicle snapshots, audit timestamps, and production indexes.
- Vehicle and commute schedule schemas now include active/date-window fields and `SCOOTY`/`BIKE` database constraints.

### Flutter App

- Flutter app scaffold created.
- SheGo logo added to `assets/images/shego_logo.png`.
- Logo registered in `pubspec.yaml`.
- Splash screen added with logo, purple/pink gradient, and tagline.
- Signup selection screen added with separate rider and driver flows.
- Rider signup UI added with DOB age calculation, guardian-field reveal, guardian consent, and validation messages.
- Driver signup UI added with KYC, license, vehicle, insurance, and female-adult validation.
- Rider and driver login screens added.
- Admin UI actions added for minor riders, guardian approvals, and driver KYC queues.
- App bar logo added.
- Branded loading state added.
- Screens added for safety/SOS, commute, child ride, subscriptions, delivery, and admin.
- API client added for backend connection.
- Android and iOS launcher icons generated from SheGo logo.

### Documentation

- README updated with setup, backend, Flutter, DB, Redis, env vars, API testing, and deployment reference.
- AWS deployment guide added at `docs/AWS_DEPLOYMENT_GUIDE.md`.
- Backend completion audit added at `docs/BACKEND_COMPLETION_AUDIT.md`.

### Verification

- Backend compile/test passed locally using JDK 17 override:

```bash
mvn -Djava.version=17 test
```

- Flutter checks passed:

```bash
flutter analyze
flutter test
```

The backend project still targets Java 21 as required. Local Maven currently uses Java 17, so production verification should use JDK 21.

## What Still Needs To Be Done for Real-World Production Use

### 1. SMS OTP Provider Integration

Current state:

- OTP is generated, stored in Redis, rate-limited, and verified.
- OTP is not sent through a real SMS provider yet.

Needed:

- Integrate providers such as AWS SNS, Twilio, MSG91, Gupshup, or Exotel.
- Add OTP message templates.
- Add provider failure handling.
- Add audit-safe logging without exposing OTP values.

### 2. Google Maps Integration

Current state:

- Basic haversine distance estimate exists.
- WebSocket live location exists.

Needed:

- Google Maps Directions API for route and ETA.
- Places API for pickup/drop search.
- Nearby police stations/hospitals.
- Route drawing data for Flutter.
- Route deviation detection.
- Main-road preference for late-night rides.

### 3. Push, SMS, and Email Notifications

Current state:

- Notification records are stored.
- Some ride event hooks create notification records.

Needed:

- FCM/APNs push notification integration.
- SMS notification provider.
- Email provider such as AWS SES.
- Retry mechanism.
- Notification delivery status.
- Guardian-specific alert templates.

### 4. Payment Gateway and Invoices

Current state:

- Payment initiate/confirm/refund APIs exist.
- Cash and future online/wallet methods are modeled.

Needed:

- Razorpay/PhonePe/Stripe/Cashfree integration.
- Payment webhook verification.
- Refund webhook handling.
- Invoice number generation.
- PDF invoice generation.
- GST/tax logic if required.

### 5. Advanced Safety Automation

Current state:

- Safety event model/API exists.
- Safety score is rule-based.
- Late-night policy API exists.

Needed:

- Automated route deviation detection.
- Unusual stop detection.
- Long-stop alert job.
- Driver moving away from route alert.
- Smooth driving score from telemetry.
- Risk score based on time, route, incident history, and map context.

### 6. Legal Audio Recording Flow

Current state:

- Audio recording is only noted as a future safety feature.

Needed:

- Consent screen.
- Region-specific legal checks.
- Encrypted upload to S3.
- Retention policy.
- Admin access audit trail.

### 7. Full Admin Dashboard UI

Current state:

- Backend admin APIs exist.
- Flutter has a basic admin screen.

Needed:

- Full admin dashboard, preferably React or Flutter web.
- KYC review queue.
- Driver approval queue.
- Active ride map.
- SOS command center.
- Complaint moderation.
- Payments/subscriptions reports.
- Safety score monitoring.

### 8. Production Hardening

Needed:

- Integration tests.
- Unit tests for services.
- Testcontainers for PostgreSQL/Redis.
- Rate limiting for login APIs.
- Sensitive-field encryption.
- Data retention cleanup jobs for location data.
- Observability with metrics and tracing.
- CI/CD pipeline.
- Secrets Manager or SSM Parameter Store.
- WAF and API throttling.

### 9. Mobile App Completion

Current state:

- Flutter scaffold exists with core screens and API calls.

Needed:

- Rider app production UX.
- Driver app production UX.
- Real map view.
- Real location permissions.
- Push notification handling.
- Background location tracking.
- SOS long-press interaction.
- Guardian contact picker.
- KYC document capture/upload.
- Payment UI.
- Rating/complaint UI.

### 10. Future Integrations

Needed:

- Wearable SOS integration.
- Voice trigger like “Help me”.
- Advanced fraud detection.
- ML-based driver/rider risk scoring.
- Corporate transport workflows.
- Women delivery partner onboarding.

## Deployment and User Release Process

The production deployment process is documented here:

- Backend/AWS deployment: `docs/AWS_DEPLOYMENT_GUIDE.md`
- Play Store and user release: `docs/PLAYSTORE_AND_USER_RELEASE_GUIDE.md`

The Play Store guide covers:

- Google Play Console account requirement.
- Developer registration fee.
- App signing.
- Android App Bundle build.
- Store listing.
- Data Safety form.
- Privacy policy.
- Testing tracks.
- Production rollout.
- Rider, driver, guardian, and admin usage flows.

## Prompt for Remaining Backend Work

Use this prompt in a future coding session:

```text
Continue the SheGo Spring Boot backend from the existing repository.

Goal:
Make the backend production-ready by completing real integrations and hardening.

Tasks:
1. Integrate a real SMS OTP provider behind an interface.
   - Keep Redis OTP storage and rate limiting.
   - Add provider config, failure handling, and tests.

2. Integrate Google Maps.
   - Add Places autocomplete endpoint.
   - Add Directions/ETA endpoint.
   - Store encoded route polyline on Ride.
   - Add route deviation detection from live location updates.
   - Add nearby police station/hospital lookup for late-night rides.

3. Add production notification delivery.
   - FCM/APNs push notification service.
   - SMS notification service.
   - Email notification service.
   - Retry logic and delivery status.
   - Guardian-specific ride start/end/SOS templates.

4. Add payment gateway integration.
   - Use Razorpay or Cashfree for India.
   - Create payment order API.
   - Verify webhook signatures.
   - Handle payment success/failure/refund webhooks.
   - Generate invoice numbers and invoice records.

5. Add safety automation.
   - Route deviation alerts.
   - Unusual stop detection.
   - Long-stop scheduled checks.
   - Late-night risk score.
   - Safety score recalculation after complaints, SOS, route deviation, and ride completion.

6. Add production tests.
   - Unit tests for AuthService, RideService, KycService, SafetyScoreService.
   - Integration tests with Testcontainers for PostgreSQL and Redis.
   - Controller tests for important APIs.

7. Add data retention and cleanup.
   - Scheduled cleanup for old location data.
   - Keep SOS/safety evidence based on retention policy.

Constraints:
- Do not add auto, car, taxi, or mixed-gender ride support.
- VehicleType must remain only SCOOTY and BIKE.
- Riders and drivers are women only.
- Do not remove existing working code.
- Follow the existing package structure and coding style.
- Keep APIs backward compatible unless a migration is documented.

Deliverables:
- Code changes.
- Flyway migrations if schema changes.
- Tests.
- README update.
- Environment variable documentation.
```

## Prompt for Remaining Flutter App Work

Use this prompt in a future coding session:

```text
Continue the SheGo Flutter app from the existing `shego_flutter` project.

Goal:
Turn the scaffold into production-ready Rider and Driver app experiences connected to the Spring Boot backend.

Tasks:
1. Add app architecture.
   - Create folders for api, models, screens, widgets, state, theme, and utils.
   - Move API calls out of main.dart.
   - Add secure token storage.

2. Complete Rider flow.
   - Registration/login/OTP.
   - KYC upload with camera/file picker.
   - Pickup/drop search.
   - Google Map route display.
   - Fare estimate.
   - Book ride.
   - Track driver live.
   - Start/complete/cancel status UI.
   - Guardian sharing.
   - SOS long press.
   - Rating and complaint flow.

3. Complete Driver flow.
   - Driver onboarding.
   - KYC/license/vehicle upload.
   - Online/offline toggle.
   - Live location publishing.
   - Incoming ride request screen.
   - Accept/reject ride.
   - Start ride with OTP.
   - Complete ride.
   - Earnings screen.

4. Complete safety features.
   - Trusted contacts UI.
   - Trusted drivers UI.
   - Late-night safety mode UI.
   - SOS active state and resolution updates.
   - Nearby police/hospital display from backend.

5. Complete Phase 2/3/4 screens.
   - Commute scheduling.
   - Child ride booking.
   - Subscriptions.
   - Payments.
   - Women delivery request flow.

6. Improve UX quality.
   - Loading states.
   - Empty states.
   - Error messages.
   - Form validation.
   - Responsive layouts.
   - Accessibility labels.

Constraints:
- Keep the SheGo logo unchanged.
- Use `assets/images/shego_logo.png` for logo, splash, and loading where appropriate.
- Do not add auto, car, taxi, or mixed-gender options.
- Vehicle options must only be SCOOTY and BIKE.

Deliverables:
- Flutter code changes.
- Updated tests.
- Updated README run instructions.
```

## Prompt for Admin Dashboard Work

Use this prompt in a future coding session:

```text
Build the SheGo admin dashboard as a production-ready web app.

Recommended frontend:
React with TypeScript, or Flutter web if staying in one frontend stack.

Required screens:
1. Login.
2. Dashboard overview.
3. Rider management.
4. Driver management.
5. KYC approval queue.
6. Driver approval queue.
7. Active rides map.
8. SOS command center.
9. Complaints and support tickets.
10. Payments and refunds.
11. Subscriptions.
12. Safety score monitoring.
13. Reports.
14. Admin audit log.

Backend:
Use the existing Spring Boot APIs. Add missing admin APIs only if needed.

Requirements:
- Role-based access for ADMIN and SUPPORT.
- Loading, empty, and error states.
- Audit-sensitive actions require confirmation.
- Do not expose private KYC documents publicly.
- Show only signed/private access links for documents.

Deliverables:
- Admin frontend project.
- API client.
- Screens.
- README setup steps.
- Deployment notes for S3 + CloudFront or ECS.
```

## Suggested Next Order

1. SMS OTP provider.
2. Google Maps route/ETA and pickup/drop search.
3. Flutter rider booking flow with map.
4. Driver app flow with live location publishing.
5. Push notifications.
6. Payment gateway.
7. Admin dashboard.
8. Safety automation jobs.
9. Integration tests and CI/CD.
