create table users (
    id uuid primary key,
    created_at timestamptz not null,
    updated_at timestamptz not null,
    full_name varchar(255) not null,
    mobile_number varchar(255) not null unique,
    email varchar(255) unique,
    password_hash varchar(255),
    account_status varchar(32) not null,
    female_verified boolean not null
);

create table user_roles (
    user_id uuid not null references users(id),
    roles varchar(32) not null
);

create table rider_profile (
    id uuid primary key,
    created_at timestamptz not null,
    updated_at timestamptz not null,
    user_id uuid not null references users(id),
    kyc_status varchar(32),
    emergency_preference varchar(255),
    average_rating double precision not null
);

create table driver_profile (
    id uuid primary key,
    created_at timestamptz not null,
    updated_at timestamptz not null,
    user_id uuid not null references users(id),
    license_number varchar(255) not null unique,
    kyc_status varchar(32),
    available boolean not null,
    online boolean not null,
    admin_approved boolean not null,
    background_verified boolean not null,
    average_rating double precision not null,
    completed_rides integer not null
);

create table vehicle (
    id uuid primary key,
    created_at timestamptz not null,
    updated_at timestamptz not null,
    driver_id uuid not null references driver_profile(id),
    vehicle_type varchar(32) not null,
    registration_number varchar(255) not null unique,
    insurance_policy_number varchar(255),
    model varchar(255)
);

create table kyc_document (
    id uuid primary key,
    created_at timestamptz not null,
    updated_at timestamptz not null,
    user_id uuid not null references users(id),
    document_type varchar(255) not null,
    private_storage_key varchar(255) not null,
    masked_document_number varchar(255),
    status varchar(32),
    rejection_reason varchar(255)
);

create table ride (
    id uuid primary key,
    created_at timestamptz not null,
    updated_at timestamptz not null,
    rider_id uuid not null references rider_profile(id),
    driver_id uuid references driver_profile(id),
    vehicle_type varchar(32) not null,
    status varchar(32) not null,
    pickup_lat double precision not null,
    pickup_lng double precision not null,
    drop_lat double precision not null,
    drop_lng double precision not null,
    pickup_address varchar(255),
    drop_address varchar(255),
    distance_km double precision not null,
    eta_minutes integer not null,
    estimated_fare numeric(38,2),
    final_fare numeric(38,2),
    start_otp varchar(255),
    completion_otp varchar(255),
    guardian_mode_enabled boolean not null,
    late_night boolean not null,
    payment_method varchar(32),
    accepted_at timestamptz,
    started_at timestamptz,
    completed_at timestamptz,
    cancelled_at timestamptz
);

create table ride_location (
    id uuid primary key,
    created_at timestamptz not null,
    updated_at timestamptz not null,
    ride_id uuid not null references ride(id),
    user_id uuid not null references users(id),
    latitude double precision not null,
    longitude double precision not null,
    speed_kmph double precision not null,
    bearing double precision not null
);

create table guardian_contact (
    id uuid primary key,
    created_at timestamptz not null,
    updated_at timestamptz not null,
    rider_id uuid not null references rider_profile(id),
    name varchar(255),
    mobile_number varchar(255),
    relationship varchar(255),
    auto_share_late_night boolean not null
);

create table trusted_driver (
    id uuid primary key,
    created_at timestamptz not null,
    updated_at timestamptz not null,
    rider_id uuid not null references rider_profile(id),
    driver_id uuid not null references driver_profile(id)
);

create table sos_alert (
    id uuid primary key,
    created_at timestamptz not null,
    updated_at timestamptz not null,
    triggered_by_id uuid not null references users(id),
    ride_id uuid references ride(id),
    latitude double precision not null,
    longitude double precision not null,
    message varchar(255),
    status varchar(32),
    resolved_at timestamptz,
    resolution_notes varchar(255)
);

create table safety_event (
    id uuid primary key,
    created_at timestamptz not null,
    updated_at timestamptz not null,
    ride_id uuid references ride(id),
    actor_id uuid not null references users(id),
    event_type varchar(255),
    severity varchar(255),
    details varchar(255)
);

create table safety_score (
    id uuid primary key,
    created_at timestamptz not null,
    updated_at timestamptz not null,
    driver_id uuid not null references driver_profile(id),
    score integer not null,
    route_deviation_count integer not null,
    complaint_count integer not null,
    emergency_incident_count integer not null,
    explanation varchar(255)
);

create table child_ride (
    id uuid primary key,
    created_at timestamptz not null,
    updated_at timestamptz not null,
    guardian_id uuid not null references rider_profile(id),
    driver_id uuid references driver_profile(id),
    child_name varchar(255),
    pickup_otp varchar(255),
    drop_otp varchar(255),
    status varchar(255),
    scheduled_at timestamptz
);

create table subscription_plan (
    id uuid primary key,
    created_at timestamptz not null,
    updated_at timestamptz not null,
    name varchar(255),
    description varchar(255),
    monthly_price numeric(38,2),
    active boolean not null
);

create table user_subscription (
    id uuid primary key,
    created_at timestamptz not null,
    updated_at timestamptz not null,
    user_id uuid not null references users(id),
    plan_id uuid not null references subscription_plan(id),
    status varchar(32),
    starts_at timestamptz,
    ends_at timestamptz
);

create table payment (
    id uuid primary key,
    created_at timestamptz not null,
    updated_at timestamptz not null,
    payer_id uuid not null references users(id),
    ride_id uuid references ride(id),
    amount numeric(38,2),
    method varchar(32),
    status varchar(32),
    provider_reference varchar(255)
);

create table driver_earning (
    id uuid primary key,
    created_at timestamptz not null,
    updated_at timestamptz not null,
    driver_id uuid not null references driver_profile(id),
    ride_id uuid not null references ride(id),
    gross_fare numeric(38,2),
    platform_commission numeric(38,2),
    net_earning numeric(38,2)
);

create table rating (
    id uuid primary key,
    created_at timestamptz not null,
    updated_at timestamptz not null,
    ride_id uuid not null references ride(id),
    rated_by_id uuid not null references users(id),
    rated_user_id uuid not null references users(id),
    overall_rating integer not null,
    safety_rating integer not null,
    comfort_rating integer not null,
    driving_behavior_rating integer not null,
    comments varchar(255),
    unsafe_reported boolean not null
);

create table complaint (
    id uuid primary key,
    created_at timestamptz not null,
    updated_at timestamptz not null,
    raised_by_id uuid not null references users(id),
    ride_id uuid references ride(id),
    category varchar(32),
    status varchar(32),
    description varchar(255),
    resolution varchar(255)
);

create table notification (
    id uuid primary key,
    created_at timestamptz not null,
    updated_at timestamptz not null,
    user_id uuid not null references users(id),
    channel varchar(255),
    title varchar(255),
    body varchar(255),
    sent boolean not null
);

create table admin_action_log (
    id uuid primary key,
    created_at timestamptz not null,
    updated_at timestamptz not null,
    admin_id uuid not null references users(id),
    action varchar(255),
    target_type varchar(255),
    target_id varchar(255),
    notes varchar(255)
);
