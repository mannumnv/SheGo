alter table driver_profile
    add column if not exists verification_status varchar(32) not null default 'INCOMPLETE',
    add column if not exists verification_rejection_reason varchar(1000),
    add column if not exists profile_photo_data text,
    add column if not exists aadhaar_document_data text,
    add column if not exists license_document_data text,
    add column if not exists vehicle_document_data text,
    add column if not exists insurance_document_data text;

update driver_profile
set verification_status = case
    when admin_approval_status = 'APPROVED' and admin_approved = true then 'APPROVED'
    when admin_approval_status = 'REJECTED' then 'REJECTED'
    when coalesce(profile_photo_storage_key, selfie_storage_key, aadhaar_storage_key, license_storage_key, vehicle_document_storage_key, insurance_document_storage_key) is not null then 'PENDING_VERIFICATION'
    else 'INCOMPLETE'
end
where verification_status is null or verification_status = 'INCOMPLETE';
