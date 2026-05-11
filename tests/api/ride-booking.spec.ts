import { test, expect } from '@playwright/test';
import { RideClient } from '../clients/rideClient';
import { RiderClient } from '../clients/riderClient';
import { adultFemaleRider } from '../fixtures/testUsers';
import { createApprovedRiderAndDriver, requireAdmin } from '../utils/flow';
import { expectBadRequest, expectNoSensitiveData, expectOk } from '../utils/assertions';

test.describe('Ride booking APIs', () => {
  test('unapproved rider cannot book ride', async ({ request }) => {
    const riders = new RiderClient(request);
    const rides = new RideClient(request);
    const token = await riders.signupToken(adultFemaleRider());
    await expectBadRequest(await rides.book(token), 'Only approved riders can book rides');
  });

  test('approved rider can book and driver accept shares safe participant details', async ({ request }) => {
    requireAdmin();
    const rides = new RideClient(request);
    const flow = await createApprovedRiderAndDriver(request);

    const booked = await expectOk(await rides.book(flow.riderToken, 'SCOOTY'));
    expect(booked.status).toBe('REQUESTED');

    const accepted = await expectOk(await rides.accept(flow.driverToken, booked.id));
    expect(accepted.status).toBe('ACCEPTED');
    expect(accepted.riderView.driver.fullName).toBe(flow.driverPayload.fullName);
    expect(accepted.riderView.driver.vehicleType).toBe('SCOOTY');
    expect(accepted.driverView.rider.fullName).toBe(flow.riderPayload.fullName);
    expect(accepted.driverView.pickupAddress).toContain('Connaught');
    expectNoSensitiveData(accepted);
    expect(JSON.stringify(accepted)).not.toContain(flow.driverPayload.address);
  });
});
