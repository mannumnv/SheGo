import { test, expect } from '@playwright/test';
import { DriverClient } from '../clients/driverClient';
import { apiUrl, auth } from '../clients/authClient';
import { adultFemaleDriver } from '../fixtures/testUsers';
import { adminClient, requireAdmin } from '../utils/flow';
import { expectBadRequest, expectOk } from '../utils/assertions';

const documents = {
  profilePhotoData: 'local-db-profile-photo',
  aadhaarDocumentData: 'local-db-aadhaar-photo',
  licenseDocumentData: 'local-db-license-photo',
  vehicleDocumentData: 'local-db-vehicle-photo',
  insuranceDocumentData: 'local-db-insurance-photo',
};

function manualOnlyDriver() {
  return adultFemaleDriver({
    profilePhotoStorageKey: null,
    selfieStorageKey: null,
    aadhaarStorageKey: null,
    licenseStorageKey: null,
    vehicleDocumentStorageKey: null,
    insuranceDocumentStorageKey: null,
  });
}

test.describe('Driver post-login verification flow', () => {
  test.beforeEach(() => requireAdmin());

  test('manual signup succeeds, documents move status to pending, admin approval unlocks active toggle', async ({ request }) => {
    const drivers = new DriverClient(request);
    const admin = await adminClient(request);
    const payload = manualOnlyDriver();
    const token = await drivers.signupToken(payload);

    const profile = await expectOk(await drivers.profile(token));
    expect(profile.verificationStatus).toBe('INCOMPLETE');
    const signupNotifications = await expectOk(await request.get(apiUrl('/api/notifications'), { headers: auth(token) }));
    expect(signupNotifications.some((item: any) => item.title === 'Upload required KYC documents')).toBe(true);
    await expectBadRequest(await drivers.availability(token, true, true), 'documents must be approved');

    const submitted = await expectOk(await drivers.submitDocuments(token, documents));
    expect(submitted.verificationStatus).toBe('PENDING_VERIFICATION');
    expect(submitted.documentsComplete).toBe(true);
    await expectBadRequest(await drivers.submitDocuments(token, {
      ...documents,
      licenseDocumentData: 'should-not-save-while-pending',
    }), 'cannot be re-submitted');
    await expectBadRequest(await drivers.availability(token, true, true), 'documents must be approved');

    const pending = await expectOk(await admin.pendingDriverKyc());
    expect(pending.some((driver: any) => driver.driverId === profile.id)).toBe(true);

    await expectOk(await admin.approveDriverVerification(profile.id));
    const approved = await expectOk(await drivers.profile(token));
    expect(approved.verificationStatus).toBe('APPROVED');
    await expectBadRequest(await drivers.submitDocuments(token, {
      ...documents,
      licenseDocumentData: 'should-not-save-after-approval',
    }), 'cannot be re-submitted');
    const approvedNotifications = await expectOk(await request.get(apiUrl('/api/notifications'), { headers: auth(token) }));
    expect(approvedNotifications.some((item: any) => item.title === 'Driver verification approved' && item.read === false)).toBe(true);

    const active = await expectOk(await drivers.availability(token, true, true));
    expect(active.available).toBe(true);
    expect(active.online).toBe(true);
  });

  test('admin driver details list shows manual signup and profile approval keeps documents inactive', async ({ request }) => {
    const drivers = new DriverClient(request);
    const admin = await adminClient(request);
    const payload = manualOnlyDriver();
    const token = await drivers.signupToken(payload);
    const profile = await expectOk(await drivers.profile(token));

    const page = await expectOk(await admin.drivers(0, 10));
    expect(page.content.some((driver: any) => driver.driverId === profile.id)).toBe(true);
    const listed = page.content.find((driver: any) => driver.driverId === profile.id);
    expect(listed.documentSubmissionStatus).toBe('DOCUMENTS_PENDING');
    expect(listed.driverApprovalStatus).toBe('PENDING');
    expect(listed.profileActiveStatus).toBe('INACTIVE');

    const details = await expectOk(await admin.driver(profile.id));
    expect(details.driverId).toBe(profile.id);
    expect(details.mobileNumber).toBe(payload.mobileNumber);
    expect(details.vehicleRegistrationNumber).toBe(payload.vehicleRegistrationNumber);
    expect(details.aadhaarVerificationStatus).toBe('MISSING');
    expect(details.drivingLicenseStatus).toBe('MISSING');
    expect(details.insuranceStatus).toBe('MISSING');

    await expectOk(await admin.approveDriverVerification(profile.id));
    const approvedProfile = await expectOk(await drivers.profile(token));
    expect(approvedProfile.adminApprovalStatus).toBe('APPROVED');
    expect(approvedProfile.verificationStatus).toBe('INCOMPLETE');
    expect(approvedProfile.available).toBe(false);
    expect(approvedProfile.online).toBe(false);
    await expectBadRequest(await drivers.availability(token, true, true), 'documents must be approved');

    const notifications = await expectOk(await request.get(apiUrl('/api/notifications'), { headers: auth(token) }));
    expect(notifications.some((item: any) => item.body === 'Your driver profile has been approved. Please upload required documents within 24 hours to activate your profile.')).toBe(true);
  });

  test('admin rejection stores reason and driver can resubmit for approval', async ({ request }) => {
    const drivers = new DriverClient(request);
    const admin = await adminClient(request);
    const token = await drivers.signupToken(manualOnlyDriver());
    const profile = await expectOk(await drivers.profile(token));

    await expectOk(await drivers.submitDocuments(token, documents));
    await expectOk(await admin.rejectDriverVerification(profile.id, 'License photo is unclear'));

    const rejected = await expectOk(await drivers.profile(token));
    expect(rejected.verificationStatus).toBe('REJECTED');
    expect(rejected.verificationRejectionReason).toContain('License photo is unclear');
    const rejectedNotifications = await expectOk(await request.get(apiUrl('/api/notifications'), { headers: auth(token) }));
    expect(rejectedNotifications.some((item: any) => item.title === 'Driver verification rejected' && `${item.body}`.includes('License photo is unclear'))).toBe(true);
    await expectBadRequest(await drivers.availability(token, true, true), 'documents must be approved');

    const resubmitted = await expectOk(await drivers.submitDocuments(token, {
      ...documents,
      licenseDocumentData: 'local-db-license-photo-clear',
    }));
    expect(resubmitted.verificationStatus).toBe('PENDING_VERIFICATION');
    expect(resubmitted.verificationRejectionReason).toBeFalsy();

    await expectOk(await admin.approveDriverVerification(profile.id));
    const active = await expectOk(await drivers.availability(token, true, true));
    expect(active.available).toBe(true);
  });

  test('admin can request re-submission after approval and driver can upload again', async ({ request }) => {
    const drivers = new DriverClient(request);
    const admin = await adminClient(request);
    const token = await drivers.signupToken(manualOnlyDriver());
    const profile = await expectOk(await drivers.profile(token));

    await expectOk(await drivers.submitDocuments(token, documents));
    await expectOk(await admin.approveDriverVerification(profile.id));
    await expectBadRequest(await drivers.submitDocuments(token, documents), 'cannot be re-submitted');

    const requested = await expectOk(await admin.requestDriverResubmission(profile.id, 'Aadhaar photo needs a clearer crop'));
    expect(requested.verificationStatus).toBe('RESUBMISSION_REQUIRED');
    const status = await expectOk(await drivers.profile(token));
    expect(status.verificationStatus).toBe('RESUBMISSION_REQUIRED');
    expect(status.verificationRejectionReason).toContain('clearer crop');

    const resubmitted = await expectOk(await drivers.submitDocuments(token, {
      ...documents,
      aadhaarDocumentData: 'local-db-aadhaar-photo-cropped',
    }));
    expect(resubmitted.verificationStatus).toBe('PENDING_VERIFICATION');
  });
});
