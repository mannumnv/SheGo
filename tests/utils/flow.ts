import { APIRequestContext, test } from '@playwright/test';
import { AuthClient } from '../clients/authClient';
import { RiderClient } from '../clients/riderClient';
import { DriverClient } from '../clients/driverClient';
import { AdminClient } from '../clients/adminClient';
import { adultFemaleDriver, adultFemaleRider } from '../fixtures/testUsers';
import { expectOk } from './assertions';

export function requireAdmin() {
  const mobile = process.env.ADMIN_MOBILE;
  const password = process.env.ADMIN_PASSWORD;
  test.skip(!mobile || !password, 'ADMIN_MOBILE and ADMIN_PASSWORD are required for this test');
  return { mobile: mobile!, password: password! };
}

export async function adminClient(request: APIRequestContext): Promise<AdminClient> {
  const { mobile, password } = requireAdmin();
  const auth = new AuthClient(request);
  const token = await auth.loginToken(mobile, password);
  return new AdminClient(request, token);
}

export async function createApprovedRiderAndDriver(request: APIRequestContext) {
  const riders = new RiderClient(request);
  const drivers = new DriverClient(request);
  const auth = new AuthClient(request);
  const admin = await adminClient(request);

  const riderPayload = adultFemaleRider();
  const riderToken = await riders.signupToken(riderPayload);
  const riderProfile = await expectOk(await riders.profile(riderToken));
  const riderUser = await expectOk(await auth.me(riderToken));

  const driverPayload = adultFemaleDriver();
  const driverToken = await drivers.signupToken(driverPayload);
  const driverProfile = await expectOk(await drivers.profile(driverToken));
  const driverUser = await expectOk(await auth.me(driverToken));

  await expectOk(await admin.approveRiderVerification(riderProfile.id));
  await expectOk(await admin.approveDriverVerification(driverProfile.id));
  await expectOk(await drivers.availability(driverToken, true, true));
  await expectOk(await drivers.location(driverToken));

  return {
    riderPayload,
    driverPayload,
    riderToken,
    driverToken,
    riderProfile,
    driverProfile,
    riderUser,
    driverUser,
    admin
  };
}
