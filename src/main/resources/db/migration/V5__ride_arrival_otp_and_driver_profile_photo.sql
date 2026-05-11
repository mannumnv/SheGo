alter table ride
    add column if not exists start_otp_expires_at timestamptz,
    add column if not exists start_otp_retry_count integer not null default 0;

alter table driver_profile
    add column if not exists profile_photo_storage_key varchar(255);
