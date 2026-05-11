import { test, expect } from '@playwright/test';
import { RiderClient } from '../clients/riderClient';
import { DriverClient } from '../clients/driverClient';
import { adultFemaleDriver, adultFemaleRider } from '../fixtures/testUsers';
import { expectBadRequest, expectOk } from '../utils/assertions';
import { adminClient, requireAdmin } from '../utils/flow';
import { AdminClient } from '../clients/adminClient';

test.describe('Admin approval APIs', () => {
  test.beforeEach(() => requireAdmin());

  test('admin JWT can access pending driver verification and non-admin cannot', async ({ request }) => {
    const admin = await adminClient(request);
    const response = await admin.pendingDriverKyc();
    expect(response.status(), await response.text()).toBe(200);

    const riders = new RiderClient(request);
    const riderToken = await riders.signupToken(adultFemaleRider());
    const nonAdmin = new AdminClient(request, riderToken);
    const forbidden = await nonAdmin.pendingDriverKyc();
    expect(forbidden.status()).toBe(403);
  });

  test('pending driver appears, admin can view and approve, approved driver can go online', async ({ request }) => {
    const drivers = new DriverClient(request);
    const admin = await adminClient(request);
    const token = await drivers.signupToken(adultFemaleDriver());
    const profile = await expectOk(await drivers.profile(token));

    const pending = await expectOk(await admin.pendingDriverKyc());
    const pendingDriver = pending.find((driver: any) => driver.driverId === profile.id);
    expect(pendingDriver).toBeTruthy();
    expect(pendingDriver.userId).toBeTruthy();
    expect(pendingDriver.fullName).toBeTruthy();
    expect(pendingDriver.mobileNumber).toBeTruthy();
    expect(pendingDriver.kycStatus).toBe('PENDING');
    expect(pendingDriver.adminApprovalStatus).toBe('PENDING');
    expect(pendingDriver.adminApproved).toBe(false);
    expect(pendingDriver.vehicleType).toBeTruthy();
    expect(pendingDriver.vehicleRegistrationNumber).toBeTruthy();
    expect(JSON.stringify(pendingDriver).toLowerCase()).not.toContain('aadhaarnumber');
    expect(JSON.stringify(pendingDriver).toLowerCase()).not.toContain('encrypted');

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
