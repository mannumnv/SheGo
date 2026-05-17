import { test, expect } from '@playwright/test';
import { AdminClient } from '../clients/adminClient';
import { AuthClient } from '../clients/authClient';
import { DriverClient } from '../clients/driverClient';
import { adultFemaleDriver } from '../fixtures/testUsers';
import { password } from '../fixtures/testData';
import { adminClient, requireAdmin } from '../utils/flow';
import { expectBadRequest, expectOk } from '../utils/assertions';

const docs = {
  profilePhotoData: 'e2e-profile-photo',
  aadhaarDocumentData: 'e2e-aadhaar-photo',
  licenseDocumentData: 'e2e-license-photo',
  vehicleDocumentData: 'e2e-vehicle-photo',
  insuranceDocumentData: 'e2e-insurance-photo',
};

function signupPayload() {
  return adultFemaleDriver({
    profilePhotoStorageKey: null,
    selfieStorageKey: null,
    aadhaarStorageKey: null,
    licenseStorageKey: null,
    vehicleDocumentStorageKey: null,
    insuranceDocumentStorageKey: null,
  });
}

test.describe('Driver verification E2E API flow', () => {
  let admin: AdminClient;

  test.beforeEach(async ({ request }) => {
    requireAdmin();
    admin = await adminClient(request);
  });

  test('driver submits documents, admin approves, then active toggle is allowed', async ({ request }) => {
    const drivers = new DriverClient(request);
    const auth = new AuthClient(request);
    const payload = signupPayload();
    await expectOk(await drivers.signup(payload));

    const token = await auth.loginToken(payload.mobileNumber, password);
    const incomplete = await expectOk(await drivers.profile(token));
    expect(incomplete.verificationStatus).toBe('INCOMPLETE');
    await expectBadRequest(await drivers.availability(token, true, true), 'documents must be approved');

    const pending = await expectOk(await drivers.submitDocuments(token, docs));
    expect(pending.verificationStatus).toBe('PENDING_VERIFICATION');
    await expectBadRequest(await drivers.availability(token, true, true), 'documents must be approved');

    await expectOk(await admin.approveDriverVerification(incomplete.id));
    const approved = await expectOk(await drivers.profile(token));
    expect(approved.verificationStatus).toBe('APPROVED');

    const active = await expectOk(await drivers.availability(token, true, true));
    expect(active.online).toBe(true);
    expect(active.available).toBe(true);
  });

  test('admin rejection reason is visible and re-submission can be approved', async ({ request }) => {
    const drivers = new DriverClient(request);
    const auth = new AuthClient(request);
    const payload = signupPayload();
    await expectOk(await drivers.signup(payload));
    const token = await auth.loginToken(payload.mobileNumber, password);
    const profile = await expectOk(await drivers.profile(token));

    await expectOk(await drivers.submitDocuments(token, docs));
    await expectOk(await admin.rejectDriverVerification(profile.id, 'Insurance image is expired'));

    const rejected = await expectOk(await drivers.profile(token));
    expect(rejected.verificationStatus).toBe('REJECTED');
    expect(rejected.verificationRejectionReason).toContain('Insurance image is expired');

    await expectOk(await drivers.submitDocuments(token, {
      ...docs,
      insuranceDocumentData: 'e2e-updated-insurance-photo',
    }));
    await expectOk(await admin.approveDriverVerification(profile.id));
    const active = await expectOk(await drivers.availability(token, true, true));
    expect(active.available).toBe(true);
  });
});
