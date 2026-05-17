alter table rider_profile
    add column if not exists active boolean not null default true;
