create table commute_schedule (
    id uuid primary key,
    created_at timestamptz not null,
    updated_at timestamptz not null,
    rider_id uuid not null references rider_profile(id),
    preferred_driver_id uuid references driver_profile(id),
    commute_type varchar(32),
    frequency varchar(32),
    vehicle_type varchar(32),
    status varchar(32),
    pickup_address varchar(255),
    drop_address varchar(255),
    pickup_lat double precision not null,
    pickup_lng double precision not null,
    drop_lat double precision not null,
    drop_lng double precision not null,
    pickup_time time
);

create table delivery_request (
    id uuid primary key,
    created_at timestamptz not null,
    updated_at timestamptz not null,
    requested_by_id uuid not null references rider_profile(id),
    delivery_partner_id uuid references driver_profile(id),
    category varchar(32),
    status varchar(32),
    pickup_address varchar(255),
    drop_address varchar(255),
    item_description varchar(255)
);
