import { test, expect } from '@playwright/test';
import { DriverClient } from '../clients/driverClient';
import { adultFemaleDriver } from '../fixtures/testUsers';
import { expectBadRequest, expectOk } from '../utils/assertions';
import { adminClient, requireAdmin } from '../utils/flow';

test.describe('Admin approval APIs', () => {
  test.beforeEach(() => requireAdmin());

  test('pending driver appears, admin can view and approve, approved driver can go online', async ({ request }) => {
    const drivers = new DriverClient(request);
    const admin = await adminClient(request);
    const token = await drivers.signupToken(adultFemaleDriver());
    const profile = await expectOk(await drivers.profile(token));

    const pending = await expectOk(await admin.pendingDriverKyc());
    expect(pending.some((driver: any) => driver.id === profile.id)).toBeTruthy();

    const approved = await expectOk(await admin.approveDriverVerification(profile.id));
    expect(approved.kycStatus).toBe('APPROVED');
    expect(approved.adminApprovalStatus).toBe('APPROVED');

    const availability = await expectOk(await drivers.availability(token));
    expect(availability.online).toBe(true);
  });

  test('rejected KYC document can be rejected and unapproved driver cannot go online', async ({ request }) => {
    const drivers = new DriverClient(request);
    const admin = await adminClient(request);
    const token = await drivers.signupToken(adultFemaleDriver());

    await expectBadRequest(await drivers.availability(token), 'Driver must be KYC approved and admin approved');
    const pendingKyc = await expectOk(await admin.pendingKyc());
    if (pendingKyc.length > 0) {
      const rejected = await expectOk(await admin.rejectKyc(pendingKyc[0].id, 'Automated validation rejection'));
      expect(rejected.status).toBe('REJECTED');
    }
  });
});
