create table if not exists saved_location (
    id uuid primary key,
    created_at timestamptz not null,
    updated_at timestamptz not null,
    user_id uuid not null references users(id),
    type varchar(32) not null,
    label varchar(255) not null,
    address varchar(255) not null,
    latitude double precision not null,
    longitude double precision not null
);

create table if not exists recent_location_search (
    id uuid primary key,
    created_at timestamptz not null,
    updated_at timestamptz not null,
    user_id uuid not null references users(id),
    query_text varchar(255) not null,
    address varchar(255) not null,
    latitude double precision not null,
    longitude double precision not null
);

create table if not exists ride_route_snapshot (
    id uuid primary key,
    created_at timestamptz not null,
    updated_at timestamptz not null,
    ride_id uuid not null unique references ride(id),
    provider varchar(64),
    distance_km numeric(10, 2),
    eta_minutes integer,
    encoded_polyline text,
    route_metadata_json text
);

alter table payment
    add column if not exists base_fare numeric(10, 2),
    add column if not exists distance_fare numeric(10, 2),
    add column if not exists time_fare numeric(10, 2),
    add column if not exists platform_fee numeric(10, 2),
    add column if not exists surge_fee numeric(10, 2),
    add column if not exists invoice_number varchar(64);

create index if not exists idx_saved_location_user_id on saved_location(user_id);
create index if not exists idx_recent_location_search_user_id on recent_location_search(user_id);
create index if not exists idx_ride_route_snapshot_ride_id on ride_route_snapshot(ride_id);
create index if not exists idx_payment_ride_id on payment(ride_id);
create index if not exists idx_payment_status on payment(status);
