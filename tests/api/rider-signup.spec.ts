import { test, expect } from '@playwright/test';
import { RiderClient } from '../clients/riderClient';
import { adultFemaleRider, maleChildRider, minorFemaleRider } from '../fixtures/testUsers';
import { expectBadRequest, expectOk } from '../utils/assertions';

test.describe('Rider signup eligibility', () => {
  test('adult female rider is allowed with self Aadhaar', async ({ request }) => {
    const riders = new RiderClient(request);
    const token = await riders.signupToken(adultFemaleRider());
    const profile = await expectOk(await riders.profile(token));
    expect(profile.verificationType).toBe('SELF_AADHAAR');
    expect(profile.riderAadhaarLast4).toBeTruthy();
  });

  test('minor female rider requires guardian Aadhaar', async ({ request }) => {
    const riders = new RiderClient(request);
    await expectBadRequest(await riders.signup(minorFemaleRider({ guardianAadhaarNumber: undefined })), 'Guardian Aadhaar is required');
  });

  test('minor female rider is allowed with guardian Aadhaar', async ({ request }) => {
    const riders = new RiderClient(request);
    const token = await riders.signupToken(minorFemaleRider());
    const profile = await expectOk(await riders.profile(token));
    expect(profile.verificationType).toBe('GUARDIAN_AADHAAR');
    expect(profile.guardianAadhaarLast4).toBeTruthy();
  });

  test('male rider below 14 is allowed with guardian Aadhaar', async ({ request }) => {
    const riders = new RiderClient(request);
    const token = await riders.signupToken(maleChildRider());
    const profile = await expectOk(await riders.profile(token));
    expect(profile.ageCategory).toBe('CHILD');
    expect(profile.verificationType).toBe('GUARDIAN_AADHAAR');
  });

  test('male rider age 14 or above is rejected', async ({ request }) => {
    const riders = new RiderClient(request);
    await expectBadRequest(await riders.signup(maleChildRider({ dateOfBirth: '2010-01-01' })), 'Male riders age 14 or above are not allowed');
  });

  test('OTHER gender goes to PENDING_ADMIN_REVIEW', async ({ request }) => {
    const riders = new RiderClient(request);
    const token = await riders.signupToken(adultFemaleRider({ gender: 'OTHER', riderAadhaarNumber: undefined }));
    const profile = await expectOk(await riders.profile(token));
    expect(profile.accountStatus).toBe('PENDING_ADMIN_REVIEW');
  });
});
