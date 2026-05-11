import { test, expect } from '@playwright/test';
import { DriverClient } from '../clients/driverClient';
import { adultFemaleDriver } from '../fixtures/testUsers';
import { expectBadRequest, expectOk, expectNoSensitiveData } from '../utils/assertions';

test.describe('Driver signup validation', () => {
  test('adult female driver is allowed and response is safe', async ({ request }) => {
    const drivers = new DriverClient(request);
    const driver = adultFemaleDriver();
    const token = await drivers.signupToken(driver);
    const profile = await expectOk(await drivers.profile(token));
    expect(profile.gender).toBe('FEMALE');
    expect(profile.vehicleType).toBe(driver.vehicleType);
    expect(profile.aadhaarLast4).toBe(driver.aadhaarNumber.slice(-4));
    expectNoSensitiveData(profile);
  });

  test('male driver is rejected', async ({ request }) => {
    const drivers = new DriverClient(request);
    await expectBadRequest(await drivers.signup(adultFemaleDriver({ gender: 'MALE' })), 'Only female drivers are allowed');
  });

  test('underage driver is rejected', async ({ request }) => {
    const drivers = new DriverClient(request);
    await expectBadRequest(await drivers.signup(adultFemaleDriver({ dateOfBirth: '2012-01-01' })), 'Driver must be legally adult');
  });

  test('vehicle type only supports SCOOTY and BIKE', async ({ request }) => {
    const drivers = new DriverClient(request);
    await expectOk(await drivers.signup(adultFemaleDriver({ vehicleType: 'BIKE' })));
    await expectBadRequest(await drivers.signup(adultFemaleDriver({ vehicleType: 'CAR' })));
  });

  test('driver OpenAPI schema has no rider/guardian fields and uses aadhaarNumber', async ({ request }) => {
    const schema = await (await request.get('/v3/api-docs')).json();
    const text = JSON.stringify(schema.components?.schemas ?? {});
    expect(text).toContain('aadhaarNumber');
    expect(text).toContain('drivingLicenseNumber');
    expect(text).not.toContain('riderAadhaarNumber');
    expect(text).not.toContain('guardianAadhaarNumber');
    expect(text).not.toContain('guardianConsent');
  });
});
