alter table notification
    alter column body type varchar(1000),
    add column if not exists role varchar(32),
    add column if not exists type varchar(32) not null default 'INFO',
    add column if not exists target_type varchar(64),
    add column if not exists target_id varchar(64),
    add column if not exists route varchar(255),
    add column if not exists dedupe_key varchar(255),
    add column if not exists read boolean not null default false,
    add column if not exists archived boolean not null default false;

create unique index if not exists ux_notification_user_dedupe
    on notification(user_id, dedupe_key)
    where dedupe_key is not null;
