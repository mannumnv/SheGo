# Initial:

I want to build a women-only ride booking app named "SheGo" similar to Rapido, but focused on safety, trust, and women empowerment.

IMPORTANT:
- Backend must be built using Spring Boot.
- Frontend can be Flutter or React Native.
- This should be a production-ready scalable architecture.
- Do not miss any module.
- Build MVP first, but design should support future advanced features.

APP CONCEPT:
Create a women-only ride booking platform focused on safe and affordable urban transportation for women in India.

Platform Rules:
- Riders are women only.
- Drivers are women only.
- Only verified female drivers can provide rides.
- The platform supports only:
  - Scooty rides
  - Bike rides
- Focus is women safety, late-night travel safety, trusted drivers, office commute, college commute, metro pickup/drop, and emergency support.

IMPORTANT:
Do NOT implement:
- Auto rides
- Car rides
- Taxi rides
- Mixed-gender ride support

Architecture may remain extensible for future expansion, but current implementation must focus only on:
- Scooty rides
- Bike rides

CORE MODULES:

1. User Management
- Rider registration
- Driver registration
- Admin registration
- Role-based access control: RIDER, DRIVER, ADMIN, SUPPORT
- Mobile OTP login
- Email login optional
- JWT authentication
- Refresh token support
- Profile management
- Account status: PENDING, ACTIVE, SUSPENDED, BLOCKED

2. Women-only Verification
- KYC verification for riders and drivers
- Aadhaar/passport/license upload support
- Driver license verification
- Face verification
- Selfie verification
- Manual admin approval
- KYC status: PENDING, APPROVED, REJECTED
- Store verification documents securely

3. Driver Onboarding
- Driver personal details
- Vehicle details
- Vehicle type:
  - SCOOTY
  - BIKE
- License number
- Vehicle registration number
- Insurance details
- Availability status
- Online/offline status
- Background verification status
- Driver approval by admin

4. Ride Booking
- Rider can search nearby women drivers
- Pickup location
- Drop location
- Fare estimate
- Distance estimate
- Ride type selection
- Book ride
- Cancel ride
- Driver accept/reject ride
- Ride status:
  REQUESTED, ACCEPTED, DRIVER_ARRIVING, STARTED, COMPLETED, CANCELLED
- OTP based ride start
- OTP based ride completion optional

5. Real-time Location Tracking
- Driver live location tracking
- Rider live location tracking during ride
- Guardian live tracking link
- WebSocket support
- Google Maps integration
- Route drawing
- ETA calculation

6. Guardian Mode
When ride starts:
- Rider can select trusted contacts
- Share live ride link with trusted contacts
- Notify guardian when ride starts
- Notify guardian when ride ends
- Detect route deviation
- Detect unusual stop
- Trigger safety alert if vehicle stops too long
- Trigger alert if driver goes far from suggested route

7. Late Night Safe Ride
- Special safety mode from 10 PM to 5 AM
- Only highly verified women drivers
- Only high rating drivers
- Optional audio recording consent
- Route risk scoring
- Prefer main roads
- Show nearby police stations/hospitals
- Auto-share ride with guardian

8. SOS / Emergency System
- In-app SOS button
- Long press panic button
- Voice trigger future support like "Help me"
- Notify trusted contacts
- Notify admin support dashboard
- Share live location
- Start emergency audio recording if legally allowed
- Emergency status tracking
- Admin can monitor active SOS cases

9. Trusted Circle
- Rider can add trusted contacts
- Rider can mark favorite drivers
- Rider can request same driver again
- Scheduled pickup with trusted driver
- Family/guardian notification system

10. Office & College Commute Support
- Daily office commute support
- Daily college commute support
- Schedule daily/weekly rides
- Trusted recurring driver support
- Monthly ride pass support
- Metro station pickup/drop support

11. Child Safe Ride
- Mother/guardian can book ride for child
- Verified female drivers only
- School pickup/drop
- Pickup OTP
- Drop OTP
- Guardian live tracking
- Driver-child assignment
- Scheduled school ride
- Guardian notification on pickup and drop

12. Subscription System
- Monthly office commute pass
- College commute pass
- Premium safe ride pass
- Late-night safety pass
- Subscription status:
  ACTIVE, EXPIRED, CANCELLED
- Payment history

13. Payment System
- Cash payment
- Online payment future support
- Wallet support future
- Fare calculation
- Commission calculation
- Driver earnings
- Refund support
- Invoice generation

14. Rating & Review
- Rider rates driver
- Driver rates rider
- Safety rating
- Comfort rating
- Driving behavior rating
- Review comments
- Report unsafe behavior
- Admin review moderation

15. AI Safety Score
Create safety scoring logic based on:
- Driver rating
- KYC level
- Ride completion history
- Route deviation count
- Complaint count
- Late night ride history
- Emergency incidents
- Smooth driving score future
- Generate driver safety score from 0 to 100

16. Admin Dashboard
- View riders
- View drivers
- Approve/reject KYC
- Approve/reject drivers
- View active rides
- View SOS alerts
- View complaints
- View payments
- View subscriptions
- View safety score
- Suspend/block users
- Generate reports

17. Support & Complaint System
- Rider can raise complaint
- Driver can raise complaint
- Complaint categories:
  SAFETY, PAYMENT, BEHAVIOR, CANCELLATION, ROUTE, OTHER
- Admin/support can assign and resolve complaints
- Complaint status:
  OPEN, IN_PROGRESS, RESOLVED, CLOSED

18. Notification System
- Push notifications
- SMS notification future
- Email notification future
- Ride accepted notification
- Driver arriving notification
- Ride started notification
- Ride completed notification
- Guardian alert notification
- SOS notification
- KYC approval/rejection notification

19. Women Delivery Network Future Module
Design extensible module for:
- Women delivery partners
- Safe parcel delivery
- Pharmacy/cosmetics delivery
- Women-only delivery network
This can be future module, but architecture should support it.

TECH STACK:

Backend:
- Java 21
- Spring Boot 3.x
- Spring Security
- JWT authentication
- Spring Data JPA
- PostgreSQL
- WebSocket
- Redis for caching/live location/session
- Flyway/Liquibase for DB migration
- Maven
- Docker
- AWS deployment ready

Frontend:
- Flutter preferred
- Rider app
- Driver app
- Admin dashboard can be React

Database:
- PostgreSQL

Cache/Realtime:
- Redis
- WebSocket

Maps:
- Google Maps API

Storage:
- AWS S3 for KYC documents and profile images

Deployment:
- Docker
- AWS EC2/ECS
- RDS PostgreSQL
- S3
- CloudWatch logs

REQUIRED BACKEND STRUCTURE:

Create Spring Boot project with this package structure:

com.shego
├── auth
├── user
├── rider
├── driver
├── vehicle
├── kyc
├── ride
├── location
├── guardian
├── safety
├── sos
├── childride
├── subscription
├── payment
├── rating
├── complaint
├── notification
├── admin
├── common
├── config
└── exception

REQUIRED DATABASE ENTITIES:

- User
- RiderProfile
- DriverProfile
- Vehicle
- KycDocument
- Ride
- RideLocation
- GuardianContact
- TrustedDriver
- SosAlert
- SafetyEvent
- SafetyScore
- ChildRide
- SubscriptionPlan
- UserSubscription
- Payment
- DriverEarning
- Rating
- Complaint
- Notification
- AdminActionLog

REQUIRED ENUMS:

public enum VehicleType {
    SCOOTY,
    BIKE
}

REQUIRED API DESIGN:

Auth APIs:
- POST /api/auth/register
- POST /api/auth/login
- POST /api/auth/otp/send
- POST /api/auth/otp/verify
- POST /api/auth/refresh-token

User APIs:
- GET /api/users/me
- PUT /api/users/me
- DELETE /api/users/me

KYC APIs:
- POST /api/kyc/upload
- GET /api/kyc/status
- GET /api/admin/kyc/pending
- POST /api/admin/kyc/{id}/approve
- POST /api/admin/kyc/{id}/reject

Driver APIs:
- POST /api/drivers/onboard
- PUT /api/drivers/availability
- PUT /api/drivers/location
- GET /api/drivers/nearby
- GET /api/drivers/me/earnings

Ride APIs:
- POST /api/rides/estimate
- POST /api/rides/book
- POST /api/rides/{id}/accept
- POST /api/rides/{id}/reject
- POST /api/rides/{id}/start
- POST /api/rides/{id}/complete
- POST /api/rides/{id}/cancel
- GET /api/rides/{id}
- GET /api/rides/history

Guardian APIs:
- POST /api/guardians
- GET /api/guardians
- DELETE /api/guardians/{id}
- POST /api/rides/{id}/share-live-location

SOS APIs:
- POST /api/sos/trigger
- POST /api/sos/{id}/resolve
- GET /api/admin/sos/active

Safety APIs:
- GET /api/safety/driver/{driverId}/score
- POST /api/safety/events
- GET /api/admin/safety/events

Child Ride APIs:
- POST /api/child-rides/book
- POST /api/child-rides/{id}/pickup-verify
- POST /api/child-rides/{id}/drop-verify
- GET /api/child-rides/history

Subscription APIs:
- GET /api/subscriptions/plans
- POST /api/subscriptions/purchase
- GET /api/subscriptions/me

Payment APIs:
- POST /api/payments/initiate
- POST /api/payments/confirm
- GET /api/payments/history

Rating APIs:
- POST /api/ratings
- GET /api/drivers/{id}/ratings

Complaint APIs:
- POST /api/complaints
- GET /api/complaints/me
- GET /api/admin/complaints
- POST /api/admin/complaints/{id}/resolve

Admin APIs:
- GET /api/admin/dashboard
- GET /api/admin/users
- POST /api/admin/users/{id}/suspend
- POST /api/admin/users/{id}/block
- GET /api/admin/rides/active
- GET /api/admin/reports

IMPORTANT BUSINESS RULES:

- Only verified women drivers can accept rides.
- Only approved riders can book rides.
- Driver cannot accept multiple active rides.
- Ride can start only after OTP verification.
- Guardian mode should auto-enable for late-night rides.
- SOS can be triggered before, during, or after ride.
- Safety score should update after each ride.
- Admin approval required before driver becomes active.
- KYC documents must not be publicly accessible.
- Location data should be stored carefully and cleaned after retention period.

SECURITY REQUIREMENTS:

- JWT authentication
- Role-based authorization
- Password hashing using BCrypt
- Input validation
- Global exception handling
- API response wrapper
- Audit logging for admin actions
- Secure file upload
- Rate limiting for OTP and login
- CORS configuration
- Sensitive data encryption where needed

DELIVERABLES:

1. Explain complete architecture.
2. Create backend folder structure.
3. Create database schema/entities.
4. Create DTOs.
5. Create repositories.
6. Create services.
7. Create controllers.
8. Create security configuration.
9. Create WebSocket configuration for live location.
10. Create safety score calculation service.
11. Create ride booking flow.
12. Create guardian mode flow.
13. Create SOS flow.
14. Create admin approval flow.
15. Create sample API requests/responses.
16. Create Dockerfile and docker-compose.yml.
17. Create README.md with setup steps.
18. Create future roadmap.
19. Keep code clean, modular, scalable, and production-ready.

MVP PRIORITY:

Phase 1 MVP:
- Auth
- Rider registration
- Driver registration
- KYC upload
- Admin approval
- Driver availability
- Nearby driver search
- Ride booking
- Ride accept/start/complete/cancel
- Live location WebSocket
- Guardian contacts
- SOS
- Rating
- Admin dashboard basic

Phase 2:
- Late night safe ride
- Safety score
- Trusted drivers
- Complaint system
- Payment
- Driver earnings

Phase 3:
- Child safe ride
- Subscription
- AI risk scoring
- Corporate transport

Phase 4:
- Women delivery network
- Wearable SOS integration
- Voice trigger
- Advanced fraud detection

Start by generating the backend architecture and complete Spring Boot project structure first.
Then implement module by module.
Do not skip safety, guardian, SOS, KYC, driver verification, or admin approval modules.

# Added No 1:

The backend implementation looks partially complete, but the full product is not complete yet.

Please continue the implementation and complete the remaining work.

Tasks:

1. Review the existing backend code and identify missing modules, incomplete APIs, missing DTOs, missing services, missing validations, and missing business logic.

2. Complete all pending backend work for Phase 1.

3. Implement Phase 2, Phase 3, and Phase 4 features as much as possible based on the existing SheGo requirements.

4. Create UI screens for Phase 2, Phase 3, and Phase 4 features in the Flutter app.

5. Make sure the UI connects properly with backend APIs.

6. Do not remove existing working code.

7. Follow the existing project structure and coding style.

8. Add proper error handling, loading states, empty states, and validation messages in the UI.

9. For AWS deployment, create a separate documentation file:

docs/AWS_DEPLOYMENT_GUIDE.md

This file should clearly explain:
- What AWS services are needed
- How to create RDS PostgreSQL
- How to create S3 bucket for KYC/profile images
- How to configure EC2 or ECS
- How to configure environment variables
- How to deploy Spring Boot backend
- How to deploy Flutter web/admin dashboard if applicable
- How to configure security groups
- How to configure CloudWatch logs
- How to connect backend with database, Redis, and S3
- How to run database migrations
- How to test production APIs after deployment

10. Also update README.md with:
- Local setup steps
- Backend run command
- Flutter run command
- Database setup
- Redis setup
- Environment variables
- API testing steps
- Deployment reference link to docs/AWS_DEPLOYMENT_GUIDE.md

Important:
- Keep the app name as SheGo.
- Vehicle types must remain only SCOOTY and BIKE.
- Do not add auto, car, taxi, or mixed-gender ride support.
- Riders are women only.
- Drivers are women only.
- Safety, Guardian, SOS, KYC, Admin approval, and Live Tracking must not be skipped.

First analyze what is already implemented, then continue from there.

# Added No 2:
Update the authentication, signup, rider eligibility, driver eligibility, KYC verification, backend validation logic, database schema, admin dashboard, and Flutter UI flows for the SheGo application.

IMPORTANT:
- Do not remove existing working code.
- Integrate these requirements into the current backend and Flutter apps.
- Keep the app name as "SheGo".
- Vehicle support must remain only:
  - SCOOTY
  - BIKE
- Riders are women/girls and boys below 14 only.
- Drivers must be adult verified women only.

====================================================
AUTHENTICATION & SIGNUP FLOW
====================================================

The app must have separate authentication and signup flows for:

1. Riders
2. Drivers

Create separate UI screens:

- RiderSignupScreen
- DriverSignupScreen
- RiderLoginScreen
- DriverLoginScreen
- SignupSelectionScreen

SignupSelectionScreen options:
- Continue as Rider
- Continue as Driver

====================================================
RIDER ELIGIBILITY RULES
====================================================

Riders are users who book rides.

Allowed Rider Categories:

1. Female Riders
- Girls/women of any age can use the app as riders.

2. Male Riders
- Only boys below 14 years old can use the app as riders.
- Boys age 14 or above are strictly not allowed.

3. Other Gender
- Allow signup but keep account in:
  PENDING_ADMIN_REVIEW state.

====================================================
RIDER SIGNUP FIELDS
====================================================

Rider signup must include:

- Full name
- Mobile number
- OTP verification
- Gender
- Date of birth
- Address (optional initially)
- Profile photo (optional)
- Emergency contact (recommended)
- Guardian/parent contact when required
- Consent checkbox for guardian verification

====================================================
RIDER AGE-BASED VERIFICATION RULES
====================================================

1. Female Riders Below 18
Verification Rules:
- Verification must use parent/guardian Aadhaar.
- Parent/guardian consent required.
- Guardian mobile number mandatory.
- Guardian relationship mandatory.

Allowed guardian relationships:
- Mother
- Father
- Guardian

Verification Type:
- GUARDIAN_AADHAAR

2. Female Riders Age 18 or Above
Verification Rules:
- Verification must use rider’s own Aadhaar.
- Self verification required.

Verification Type:
- SELF_AADHAAR

3. Male Riders Below 14
Verification Rules:
- Verification must always use parent/guardian Aadhaar.
- Parent/guardian consent mandatory.
- Guardian mobile number mandatory.
- Guardian relationship mandatory.

Verification Type:
- GUARDIAN_AADHAAR

4. Male Riders Age 14 or Above
- Reject signup completely.
- User cannot use the platform.

====================================================
DRIVER ELIGIBILITY RULES
====================================================

Drivers are users who provide rides.

Driver Requirements:
- Driver must be FEMALE only.
- Driver must be legally adult as per Indian driving rules.
- Driver must complete KYC.
- Driver must complete admin approval.
- Driver must upload:
  - Aadhaar
  - Driving license
  - Vehicle documents
  - Insurance details
  - Selfie verification

Vehicle support must remain only:
- SCOOTY
- BIKE

====================================================
DRIVER SIGNUP FIELDS
====================================================

Driver signup must include:

- Full name
- Mobile number
- OTP verification
- Gender
- Date of birth
- Address
- Driving license number
- Vehicle type:
  - SCOOTY
  - BIKE
- Vehicle registration number
- Insurance details
- Selfie verification
- KYC documents

====================================================
VALIDATION LOGIC
====================================================

Implement backend validation service.

Validation Rules:

1. Rider Validation

- If gender == MALE AND age >= 14:
  - Reject signup.

- If gender == FEMALE AND age < 18:
  - Guardian Aadhaar required.

- If gender == FEMALE AND age >= 18:
  - Self Aadhaar required.

- If gender == MALE AND age < 14:
  - Guardian Aadhaar required.

- If gender == OTHER:
  - Account status = PENDING_ADMIN_REVIEW

2. Driver Validation

- If driver gender != FEMALE:
  - Reject signup.

- If driver age < legal driving age:
  - Reject signup.

- Driver cannot go online until:
  - KYC completed
  - Admin approved

====================================================
BACKEND REQUIREMENTS
====================================================

Add age calculation from date of birth.

Create eligibility validation service:
- EligibilityValidationService

Add clear API validation errors.

Examples:
- "Male riders age 14 or above are not allowed."
- "Guardian Aadhaar is required for riders below 18."
- "Only female drivers are allowed."

====================================================
DATABASE UPDATES
====================================================

Add/update entities and database schema.

Rider fields:

- riderDateOfBirth
- riderAge
- riderGender
- guardianName
- guardianRelationship
- guardianMobileNumber
- guardianAadhaarNumber
- guardianConsent
- verificationType

VerificationType enum:
- SELF_AADHAAR
- GUARDIAN_AADHAAR

RiderAgeCategory enum:
- CHILD
- TEEN
- ADULT

Driver fields:
- drivingLicenseNumber
- vehicleType
- insuranceDetails
- kycStatus
- adminApprovalStatus

====================================================
UI REQUIREMENTS
====================================================

Update Flutter UI.

Rider Signup UI:
- Automatically calculate age from DOB.
- Dynamically show guardian fields when required.
- Show validation messages clearly.
- Add guardian consent checkbox.
- Show verification type automatically.

Example messages:
- "Parent/guardian verification is required for riders below 18."
- "Male riders age 14 or above are not allowed."

Driver Signup UI:
- Separate screen from rider signup.
- Driver-only KYC flow.
- Upload Aadhaar.
- Upload license.
- Upload vehicle documents.
- Upload selfie verification.
- Upload insurance documents.

====================================================
ADMIN DASHBOARD REQUIREMENTS
====================================================

Admin dashboard must show:

1. Minor Riders
- Riders below 18
- Guardian verification status
- Pending guardian approvals

2. Rider Categories
- CHILD
- TEEN
- ADULT

3. Driver Verification
- Pending KYC
- Pending admin approval
- Rejected drivers
- Approved drivers

4. Verification Monitoring
- Self Aadhaar verification
- Guardian Aadhaar verification

====================================================
SECURITY REQUIREMENTS
====================================================

- Secure Aadhaar storage
- Encrypt sensitive KYC data
- Restrict KYC access to admins only
- Secure file upload validation
- Prevent unauthorized profile access
- Add audit logs for admin verification actions

====================================================
API REQUIREMENTS
====================================================

Add/update APIs:

Rider APIs:
- POST /api/riders/signup
- POST /api/riders/login
- POST /api/riders/verify-guardian
- GET /api/riders/profile

Driver APIs:
- POST /api/drivers/signup
- POST /api/drivers/login
- POST /api/drivers/upload-kyc
- GET /api/drivers/profile

Admin APIs:
- GET /api/admin/minor-riders
- GET /api/admin/pending-guardian-verifications
- GET /api/admin/pending-driver-kyc
- POST /api/admin/approve-rider-verification
- POST /api/admin/approve-driver-verification

====================================================
FINAL REQUIREMENTS
====================================================

- Keep all existing SheGo ride booking functionality.
- Do not break existing backend modules.
- Update DTOs, entities, repositories, services, controllers, validators, and Flutter screens accordingly.
- Maintain clean architecture and production-ready coding standards.
- Add proper comments and README updates for the new verification flow.
- Update Swagger/OpenAPI documentation for all new APIs.