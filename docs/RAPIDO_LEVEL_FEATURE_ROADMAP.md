# SheGo Rapido-Level Feature Roadmap

Last updated: 2026-05-12

This roadmap lists the production features still needed to take SheGo from a stable MVP toward a Rapido-level ride booking experience while preserving the SheGo rules:

- Riders: women/girls of any age and boys below 14.
- Drivers: verified adult women only.
- Vehicles: `SCOOTY` and `BIKE` only.
- Backend: Spring Boot APIs remain the source of truth.
- Flutter apps must not connect directly to PostgreSQL, Redis, or S3.

## Current Stabilization Priority

Phase 1 must remain focused on eliminating backend `Unexpected server error` responses. Missing data, invalid IDs, wrong user roles, missing S3 configuration, and invalid ride states should return explicit API errors such as `Ride not found`, `Access denied`, or `S3 storage is not configured for this environment`.

Full production integrations should wait until the MVP flows are stable.

## Rider App

### High Priority

| Feature | Purpose | Backend/API Need | Status |
| --- | --- | --- | --- |
| Real Google Maps integration | Show pickup/drop map, markers, route preview | Google Maps API key config, route API adapter | Pending |
| Places autocomplete | Suggest pickup/drop locations | Places API backend proxy or Flutter SDK config | Pending |
| GPS current location | Use rider location for pickup | Mobile permissions, geolocation package | Pending |
| Fare breakdown | Replace raw JSON with readable fare slip | Existing estimate API can be extended | Partial |
| Recent rides and ride detail | Let rider inspect previous trips | Existing history API plus detail UI | Partial |
| KYC status UI | Show why account cannot book | Rider profile API response | Partial |
| Guardian mode visibility | Show guardian sharing state per ride | Guardian APIs and ride details | Partial |
| Ride cancellation reasons | Capture operational reason | Cancellation reason DTO and DB field | Pending |
| Feedback form with ride/driver prefill | Avoid wrong `ratedUserId` errors | Ride details response already exposes safe driver userId | Partial |

### Production-Level

| Feature | Purpose | Dependencies |
| --- | --- | --- |
| Saved locations | Home, work, college, metro stations | New saved location entity/API |
| Recent searches | Faster booking | Local cache plus optional backend history |
| Live driver map movement | Rider can track driver arrival | WebSocket location stream and map marker updates |
| ETA updates | Better confidence during pickup | Directions/traffic provider |
| Wallet/payment history | Payment transparency | Payment ledger APIs |
| Coupons/referrals | Growth and retention | Promo/referral entities and fraud checks |
| Invoice download | Compliance and receipts | Invoice generator and storage |
| Notifications | Ride accepted, driver arrived, SOS, KYC | Push provider, templates, notification log |
| Trusted driver booking | Repeat safe driver requests | Trusted driver matching logic |
| Scheduled rides | Office/college commute | Scheduling, dispatch jobs, reminders |

## Driver App

### High Priority

| Feature | Purpose | Backend/API Need | Status |
| --- | --- | --- | --- |
| WebSocket ride request popup | Driver receives live ride request | Matching + WebSocket event payload | Pending |
| Accept/reject countdown | Avoid stale requests | Dispatch timeout and request state | Pending |
| Online/offline persistence | Reliable driver availability | Existing availability API plus app restore | Partial |
| KYC checklist | Driver knows pending documents | Driver profile/KYC status API | Partial |
| Document upload UI | Driver uploads required documents | Existing storage intent + KYC APIs | Partial |
| Rider details after accept | Show ride-safe rider info only | Ride accepted response | Partial |
| OTP start flow | Start only after rider shares OTP | Existing arrive/start APIs | Partial |
| Earnings dashboard | Show daily/weekly earnings | Driver earning APIs | Partial |

### Production-Level

| Feature | Purpose | Dependencies |
| --- | --- | --- |
| Live navigation | Turn-by-turn pickup/drop guidance | Maps navigation/deep link integration |
| Wallet/settlement | Driver payouts and commissions | Settlement ledger and payout provider |
| Performance dashboard | Rating, completion, complaints | Aggregated driver metrics |
| Heatmap/hot zones | Help drivers find demand | Demand analytics and map overlays |
| Background location | Keep matching/tracking accurate | Mobile background permissions and battery policy |
| Push notifications | Ride requests and safety alerts | FCM/APNs integration |

## Admin Panel

| Feature | Purpose | Dependencies |
| --- | --- | --- |
| Dashboard charts | Operational overview | Aggregated metrics endpoints |
| KYC document preview | Review uploaded docs securely | S3 pre-signed URL with admin-only access |
| Rider verification queue | Approve adult/minor/guardian verification | Rider approval APIs |
| Guardian verification queue | Review parent/guardian Aadhaar consent | Guardian verification model/API |
| Approval/rejection remarks | Audit why action was taken | Remarks fields and admin action logs |
| Active ride monitoring map | Support live operations | WebSocket location + map UI |
| SOS monitoring | Safety operations | Active SOS API and escalation workflow |
| Complaint resolution | Support workflow | Assignment, status, SLA fields |
| Payments/refunds | Finance workflow | Payment provider integration |
| Subscriptions | Manage commute passes | Subscription admin APIs |
| Audit logs | Compliance | Admin action log list/export |
| Reports export | Business reporting | CSV/XLS/PDF export APIs |

## Google Maps

Do not wire paid production Maps blindly. Add clean adapters and configuration first.

Required work:

- Add Flutter Google Maps package.
- Configure API keys separately for Android, iOS, and web.
- Enable Places API.
- Enable Directions API.
- Draw route polylines.
- Add pickup/drop marker dragging.
- Add GPS permission prompts.
- Add fallback UI when Maps key is missing.
- Add backend configuration documentation for route/ETA providers.

## Payment

MVP can keep cash payment. Production payment should be implemented through provider adapters.

Required work:

- Cash confirmation flow.
- UPI payment mode.
- Razorpay/PhonePe/Paytm adapter layer.
- Payment polling/webhook handling.
- Failed payment retry.
- Refund workflow.
- Driver settlement ledger.
- Invoice generation and download.

## Safety

SheGo safety features should be built incrementally and tested carefully.

Required work:

- Guardian tracking link.
- Route deviation detection.
- Unusual stop detection.
- Late-night risk scoring.
- Nearby police station/hospital display.
- Emergency audio consent flow.
- SOS escalation dashboard.
- Trusted contact SMS/push alerts.

## Implementation Order

1. Stabilize backend error handling and tests.
2. Complete rider/driver happy-path MVP with safe UI fallbacks.
3. Add WebSocket ride request flow.
4. Add Maps UI with missing-key fallback.
5. Add payment provider adapter interfaces.
6. Add admin review workflows and secure document preview.
7. Add production SMS/push integrations.
8. Add advanced safety automation.

## Do Not Implement Yet

These should remain documented or interface-only until Phase 1 is stable:

- Real payment gateway.
- Real SMS provider.
- Real Google Maps paid API behavior.
- Push notification production service.
- Background location tracking.
- Advanced AI safety scoring.

