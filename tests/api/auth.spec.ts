import { test, expect } from '@playwright/test';
import { AuthClient } from '../clients/authClient';
import { RiderClient } from '../clients/riderClient';
import { DriverClient } from '../clients/driverClient';
import { adultFemaleDriver, adultFemaleRider } from '../fixtures/testUsers';
import { expectBadRequest, expectOk } from '../utils/assertions';

test.describe('Auth APIs', () => {
  test('rider signup returns JWT and JWT profile validation works', async ({ request }) => {
    const rider = adultFemaleRider();
    const riders = new RiderClient(request);
    const auth = new AuthClient(request);

    const signup = await expectOk(await riders.signup(rider));
    expect(signup.accessToken).toBeTruthy();

    const me = await expectOk(await auth.me(signup.accessToken));
    expect(me.mobileNumber).toBe(rider.mobileNumber);
  });

  test('active account can login with JWT credentials', async ({ request }) => {
    const auth = new AuthClient(request);
    const mobileNumber = `8${Date.now().toString().slice(-9)}`;
    await expectOk((await auth.register({
      fullName: 'SheGo Login Support',
      mobileNumber,
      password: 'Secret123!',
      roles: ['SUPPORT']
    })).response);
    const login = await expectOk((await auth.login(mobileNumber, 'Secret123!')).response);
    expect(login.accessToken).toBeTruthy();
  });

  test('driver signup and login', async ({ request }) => {
    const driver = adultFemaleDriver();
    const drivers = new DriverClient(request);

    const signup = await expectOk(await drivers.signup(driver));
    expect(signup.accessToken).toBeTruthy();

    const profile = await expectOk(await drivers.profile(signup.accessToken));
    expect(profile.mobileNumber).toBe(driver.mobileNumber);
  });

  test('invalid login is rejected', async ({ request }) => {
    const auth = new AuthClient(request);
    await expectBadRequest((await auth.login('9999999999', 'wrong')).response);
  });

  test('duplicate mobile number is rejected', async ({ request }) => {
    const rider = adultFemaleRider();
    const riders = new RiderClient(request);
    await expectOk(await riders.signup(rider));
    await expectBadRequest(await riders.signup(rider), 'Mobile number already registered');
  });
});
