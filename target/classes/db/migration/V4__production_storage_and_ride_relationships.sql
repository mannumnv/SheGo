do $$
begin
    if exists (
        select 1 from information_schema.columns
        where table_name = 'rider_profile' and column_name = 'guardian_aadhaar_number'
    ) and not exists (
        select 1 from information_schema.columns
        where table_name = 'rider_profile' and column_name = 'guardian_aadhaar_encrypted'
    ) then
        alter table rider_profile rename column guardian_aadhaar_number to guardian_aadhaar_encrypted;
    end if;

    if exists (
        select 1 from information_schema.columns
        where table_name = 'rider_profile' and column_name = 'rider_aadhaar_number'
    ) and not exists (
        select 1 from information_schema.columns
        where table_name = 'rider_profile' and column_name = 'rider_aadhaar_encrypted'
    ) then
        alter table rider_profile rename column rider_aadhaar_number to rider_aadhaar_encrypted;
    end if;

    if exists (
        select 1 from information_schema.columns
        where table_name = 'driver_profile' and column_name = 'aadhaar_number'
    ) and not exists (
        select 1 from information_schema.columns
        where table_name = 'driver_profile' and column_name = 'aadhaar_encrypted'
    ) then
        alter table driver_profile rename column aadhaar_number to aadhaar_encrypted;
    end if;
end $$;

alter table rider_profile
    add column if not exists guardian_aadhaar_last4 varchar(4),
    add column if not exists rider_aadhaar_last4 varchar(4);

alter table driver_profile
    add column if not exists aadhaar_last4 varchar(4);

alter table vehicle
    add column if not exists active boolean not null default true;

alter table ride
    add column if not exists vehicle_id uuid references vehicle(id),
    add column if not exists vehicle_registration_snapshot varchar(255),
    add column if not exists vehicle_model_snapshot varchar(255),
    add column if not exists assigned_at timestamptz,
    add column if not exists driver_reached_at timestamptz,
    add column if not exists rider_boarded_at timestamptz,
    add column if not exists ride_completed_at timestamptz;

alter table commute_schedule
    add column if not exists start_date date,
    add column if not exists end_date date,
    add column if not exists days_of_week varchar(64),
    add column if not exists active boolean not null default true;

do $$
begin
    if not exists (select 1 from pg_constraint where conname = 'chk_vehicle_type_vehicle') then
        alter table vehicle add constraint chk_vehicle_type_vehicle check (vehicle_type in ('SCOOTY', 'BIKE'));
    end if;
    if not exists (select 1 from pg_constraint where conname = 'chk_vehicle_type_ride') then
        alter table ride add constraint chk_vehicle_type_ride check (vehicle_type in ('SCOOTY', 'BIKE'));
    end if;
    if not exists (select 1 from pg_constraint where conname = 'chk_vehicle_type_driver_profile') then
        alter table driver_profile add constraint chk_vehicle_type_driver_profile check (vehicle_type is null or vehicle_type in ('SCOOTY', 'BIKE'));
    end if;
    if not exists (select 1 from pg_constraint where conname = 'chk_vehicle_type_commute_schedule') then
        alter table commute_schedule add constraint chk_vehicle_type_commute_schedule check (vehicle_type is null or vehicle_type in ('SCOOTY', 'BIKE'));
    end if;
end $$;

create index if not exists idx_ride_rider_id on ride(rider_id);
create index if not exists idx_ride_driver_id on ride(driver_id);
create index if not exists idx_ride_vehicle_id on ride(vehicle_id);
create index if not exists idx_vehicle_driver_id on vehicle(driver_id);
create index if not exists idx_ride_status on ride(status);
create index if not exists idx_sos_alert_status on sos_alert(status);
