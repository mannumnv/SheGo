# SheGo Database Rules

This document describes the current PostgreSQL schema rules and relationships implemented by Flyway migrations `V1` through `V4`.

## Database Ownership

PostgreSQL stores all permanent business data. Redis is not a permanent database in SheGo. AWS S3 stores uploaded file bytes, while PostgreSQL stores only the private object keys.

## Core Tables

Current permanent tables include:

- `users`
- `user_roles`
- `rider_profile`
- `driver_profile`
- `vehicle`
- `kyc_document`
- `ride`
- `ride_location`
- `guardian_contact`
- `trusted_driver`
- `sos_alert`
- `safety_event`
- `safety_score`
- `child_ride`
- `subscription_plan`
- `user_subscription`
- `payment`
- `driver_earning`
- `rating`
- `complaint`
- `notification`
- `admin_action_log`
- `commute_schedule`
- `delivery_request`

Do not remove existing tables in future migrations. Add incremental Flyway migrations.

## Identity Relationships

- `users` is the base identity table.
- `user_roles` stores roles such as `RIDER`, `DRIVER`, `ADMIN`, and `SUPPORT`.
- `rider_profile.user_id` references `users(id)`.
- `driver_profile.user_id` references `users(id)`.
- `admin_action_log.admin_id` references `users(id)`.

## Rider Profile Rules

`rider_profile` stores rider eligibility and verification fields:

- `rider_date_of_birth`
- `rider_age`
- `rider_gender`
- `rider_age_category`
- `guardian_name`
- `guardian_relationship`
- `guardian_mobile_number`
- `guardian_aadhaar_encrypted`
- `guardian_aadhaar_last4`
- `rider_aadhaar_encrypted`
- `rider_aadhaar_last4`
- `guardian_consent`
- `verification_type`
- `profile_photo_storage_key`

Full Aadhaar may be accepted during signup/KYC, but it must be encrypted before storing. Only last 4 digits are stored separately for masked display. API responses must not return encrypted or full Aadhaar.

## Driver Profile and Vehicle Rules

`driver_profile` stores driver verification data:

- `date_of_birth`
- `age`
- `gender`
- `aadhaar_encrypted`
- `aadhaar_last4`
- `driving_license_number`
- `vehicle_type`
- `vehicle_registration_number`
- `insurance_details`
- `selfie_storage_key`
- `aadhaar_storage_key`
- `license_storage_key`
- `vehicle_document_storage_key`
- `insurance_document_storage_key`
- `kyc_status`
- `admin_approval_status`

`vehicle` stores the driver vehicle:

- `driver_id`
- `vehicle_type`
- `registration_number`
- `insurance_policy_number`
- `model`
- `active`

Vehicle type is constrained to:

- `SCOOTY`
- `BIKE`

Future migrations must keep this product boundary.

## Ride Relationships

`ride` stores the operational ride record. Each ride includes:

- `rider_id` referencing `rider_profile(id)`
- `driver_id` referencing `driver_profile(id)`
- `vehicle_id` referencing `vehicle(id)`
- `vehicle_type`
- `vehicle_registration_snapshot`
- `vehicle_model_snapshot`
- `status`
- pickup/drop coordinates
- pickup/drop addresses
- distance, ETA, estimated fare, final fare
- OTP fields
- guardian and late-night flags
- payment method
- audit timestamps

Ride audit timestamps currently include:

- `accepted_at`
- `assigned_at`
- `driver_reached_at`
- `rider_boarded_at`
- `started_at`
- `completed_at`
- `ride_completed_at`
- `cancelled_at`

Ride OTP fields currently include:

- `start_otp`: stores the BCrypt hash of the ride start OTP, not the plain OTP
- `start_otp_expires_at`
- `start_otp_retry_count`

The plain ride start OTP is temporary Redis data for rider display only and must not be persisted permanently.

The vehicle snapshots are required because a driver’s active vehicle can change after a ride.

## Commute Schedule Rules

`commute_schedule` supports recurring office/college/metro travel. Current schedule fields include:

- `start_date`
- `end_date`
- `days_of_week`
- `active`

Vehicle type remains constrained to `SCOOTY` or `BIKE`.

## Indexes

Production indexes currently include:

- `idx_ride_rider_id` on `ride(rider_id)`
- `idx_ride_driver_id` on `ride(driver_id)`
- `idx_ride_vehicle_id` on `ride(vehicle_id)`
- `idx_vehicle_driver_id` on `vehicle(driver_id)`
- `idx_ride_status` on `ride(status)`
- `idx_sos_alert_status` on `sos_alert(status)`

Future high-traffic queries should add indexes through new Flyway migrations.

## File Storage Rule

Never store raw files/images in PostgreSQL. Store only S3 object keys such as:

- `private_storage_key`
- `profile_photo_storage_key`
- `aadhaar_storage_key`
- `license_storage_key`
- `vehicle_document_storage_key`
- `insurance_document_storage_key`
- `selfie_storage_key`

Pre-signed URLs are generated at request time and must not be persisted.

## Migration Rule

Use incremental Flyway migrations only. Do not edit migrations already applied to shared or production databases. Current sequence:

- `V1__initial_schema.sql`
- `V2__phase_modules.sql`
- `V3__eligibility_verification_fields.sql`
- `V4__production_storage_and_ride_relationships.sql`
- `V5__ride_arrival_otp_and_driver_profile_photo.sql`
