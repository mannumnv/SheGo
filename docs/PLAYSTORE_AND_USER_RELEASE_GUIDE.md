# SheGo Play Store and User Release Guide

This guide explains what happens after all remaining production implementation is complete: how the Android app is built, released to Google Play Store, and used by riders, drivers, admins, and support teams.

## 1. Before Play Store Release

Complete these production items first:

- Backend deployed on AWS or another production cloud.
- PostgreSQL, Redis, S3, CloudWatch, and environment variables configured.
- Real SMS OTP provider integrated.
- Google Maps API integrated.
- Push notifications integrated.
- Payment gateway integrated if online payments are enabled.
- Privacy policy and terms of service published.
- KYC document security reviewed.
- SOS and location data retention policy finalized.
- Android package name finalized.
- App icon, splash screen, and branding finalized.
- Production API URL configured in Flutter build.

## 2. Google Play Console Account

To publish SheGo on Google Play Store, you need a Google Play Console developer account.

Steps:

1. Go to Google Play Console.
2. Create a developer account.
3. Pay the one-time Google Play developer registration fee.
4. Complete identity verification.
5. Add organization/business details if publishing as a company.
6. Add payment profile if the app has paid subscriptions or in-app purchases.

Important:

- Google Play developer account is required before publishing.
- If SheGo uses paid subscriptions through Google Play Billing, additional payment/tax setup is required.
- If subscriptions are paid outside the app, review Google Play payment policy carefully.

## 3. Android App Configuration

Before building the final app:

1. Set final Android application ID/package name.
2. Configure app signing.
3. Configure release keystore.
4. Configure production API base URL.
5. Configure Google Maps Android key.
6. Configure Firebase project if using FCM push notifications.
7. Add required permissions:
   - Internet
   - Location foreground/background where legally required
   - Camera for KYC/selfie
   - Microphone only if audio recording is enabled and legally allowed
   - Notifications

The current Makefile build command:

```bash
make flutter-android-bundle
```

This creates the Play Store upload file:

```text
shego_flutter/build/app/outputs/bundle/release/app-release.aab
```

## 4. Play Store Listing

Create the app listing in Google Play Console:

1. App name: `SheGo`.
2. Short description.
3. Full description.
4. App category: Travel / Maps & Navigation or Transport-related category.
5. Upload app icon.
6. Upload screenshots:
   - Splash screen
   - Login/OTP
   - Ride booking
   - Live tracking
   - Guardian mode
   - SOS
   - Driver app screens if same app supports driver mode
7. Add feature graphic.
8. Add privacy policy URL.
9. Add support email.
10. Add website URL if available.

## 5. Play Store Compliance Forms

Complete these forms carefully:

- Data Safety form.
- App content rating.
- Target audience.
- Ads declaration.
- Financial features declaration if payments/subscriptions exist.
- Location permissions declaration.
- Background location declaration if driver/rider tracking runs in background.
- Sensitive permissions declaration for camera, microphone, SMS, or contacts.

For SheGo, pay special attention to:

- Location data collection.
- KYC document upload.
- Emergency/SOS data.
- Guardian contact data.
- Payment data.
- Audio recording if added.
- Child ride feature and child data handling.

## 6. Privacy Policy Must Mention

The privacy policy should clearly explain:

- What user data is collected.
- Why location is collected.
- When live location is shared with guardians.
- How KYC documents are stored.
- How long location history is retained.
- How SOS alerts are handled.
- How complaints and safety reports are stored.
- How payment data is processed.
- How users can request account deletion.
- How child ride data is handled.
- Contact email for privacy requests.

## 7. Testing Tracks

Recommended release order:

1. Internal testing:
   - Upload `.aab`.
   - Add internal testers.
   - Test login, KYC, ride booking, SOS, location, payments, notifications.

2. Closed testing:
   - Invite limited real users.
   - Test with real devices and real city routes.
   - Validate safety workflows.

3. Open testing:
   - Wider beta testing.
   - Monitor crash reports and backend logs.

4. Production:
   - Roll out gradually.
   - Start with a small percentage of users.
   - Monitor CloudWatch, Play Console vitals, payment failures, SOS alerts, and complaints.

## 8. Backend Production Deployment Summary

Backend deployment is covered in:

```text
docs/AWS_DEPLOYMENT_GUIDE.md
```

High-level flow:

1. Create RDS PostgreSQL.
2. Create Redis/ElastiCache.
3. Create private S3 bucket.
4. Build backend Docker image.
5. Push image to ECR.
6. Deploy to ECS or EC2.
7. Configure environment variables.
8. Run Flyway migrations.
9. Configure CloudWatch logs.
10. Test production APIs.

## 9. How Users Will Use SheGo

### Rider Flow

1. Download SheGo from Play Store.
2. Open app and see splash screen.
3. Register/login using mobile OTP.
4. Complete profile.
5. Upload KYC/selfie documents.
6. Wait for approval if required.
7. Add guardian/trusted contacts.
8. Search pickup and drop location.
9. Select `SCOOTY` or `BIKE`.
10. View fare and ETA.
11. Book ride.
12. Track verified woman driver.
13. Share ride with guardian.
14. Start ride using OTP.
15. Use SOS if needed.
16. Complete ride.
17. Pay by cash or online if enabled.
18. Rate driver and report issues if needed.

### Driver Flow

1. Download SheGo driver app or use driver mode.
2. Register/login using mobile OTP.
3. Upload KYC, license, selfie, and vehicle documents.
4. Add vehicle as `SCOOTY` or `BIKE`.
5. Wait for admin approval.
6. Go online.
7. Receive ride requests.
8. Accept or reject ride.
9. Navigate to pickup.
10. Start ride after rider OTP verification.
11. Complete ride.
12. View earnings.
13. Rate rider if enabled.

### Guardian Flow

1. Rider adds guardian contact.
2. Guardian receives ride start notification/link.
3. Guardian views live tracking link.
4. Guardian receives ride end notification.
5. Guardian may receive SOS/safety alerts.

### Admin/Support Flow

1. Admin logs in to dashboard.
2. Reviews KYC requests.
3. Approves/rejects drivers.
4. Monitors active rides.
5. Monitors SOS alerts.
6. Handles complaints.
7. Reviews payments/refunds.
8. Suspends or blocks unsafe users.
9. Generates reports.

## 10. Production Release Checklist

- Backend deployed and health checked.
- Database migrations completed.
- Redis connected.
- S3 private upload tested.
- SMS OTP tested.
- Google Maps tested.
- Push notifications tested.
- Payment gateway tested.
- SOS flow tested.
- KYC approval tested.
- Driver approval tested.
- Ride booking tested end-to-end.
- Privacy policy published.
- Terms of service published.
- Play Store listing completed.
- Data Safety form completed.
- App content rating completed.
- Internal testing completed.
- Closed testing completed.
- Production rollout plan ready.

## 11. Common Release Commands

Build Android App Bundle:

```bash
make flutter-android-bundle API_BASE_URL=https://api.shego.example.com
```

Build Android APK for direct testing:

```bash
make flutter-apk API_BASE_URL=https://api.shego.example.com
```

Build Flutter web:

```bash
make flutter-web API_BASE_URL=https://api.shego.example.com
```

Build backend Docker image:

```bash
make docker-build
```

Run backend locally:

```bash
make deps
make backend
```

## 12. Important Notes

- Play Store release usually requires `.aab`, not APK.
- APK is useful for local testing or direct installation.
- Real payments/subscriptions may require Google Play Billing depending on what is sold inside the app.
- Transport, safety, KYC, child ride, and location features need strong privacy/legal review before public launch.
- Never expose KYC files publicly.
- Never add auto, car, taxi, or mixed-gender ride support unless the product policy changes.
