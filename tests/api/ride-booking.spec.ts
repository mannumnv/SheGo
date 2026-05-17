import { test, expect } from '@playwright/test';
import { RideClient } from '../clients/rideClient';
import { RiderClient } from '../clients/riderClient';
import { DriverClient } from '../clients/driverClient';
import { adultFemaleDriver, adultFemaleRider } from '../fixtures/testUsers';
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

  test('active toggles persist and inactive rider cannot book', async ({ request }) => {
    requireAdmin();
    const rides = new RideClient(request);
    const riders = new RiderClient(request);
    const flow = await createApprovedRiderAndDriver(request);

    const inactive = await expectOk(await riders.active(flow.riderToken, false));
    expect(inactive.active).toBe(false);
    await expectBadRequest(await rides.book(flow.riderToken), 'Rider account is inactive');

    const active = await expectOk(await riders.active(flow.riderToken, true));
    expect(active.active).toBe(true);
    const booked = await expectOk(await rides.book(flow.riderToken));
    expect(booked.status).toBe('REQUESTED');

    const offline = await expectOk(await new DriverClient(request).availability(flow.driverToken, false, false));
    expect(offline.available).toBe(false);
    expect(offline.online).toBe(false);
    await expectBadRequest(await rides.accept(flow.driverToken, booked.id), 'Driver must be active');
  });

  test('multiple active drivers see request and only one can accept it', async ({ request }) => {
    requireAdmin();
    const rides = new RideClient(request);
    const drivers = new DriverClient(request);
    const flow = await createApprovedRiderAndDriver(request);

    const secondPayload = adultFemaleDriver();
    const secondDriverToken = await drivers.signupToken(secondPayload);
    const secondProfile = await expectOk(await drivers.profile(secondDriverToken));
    await expectOk(await flow.admin.approveDriverVerification(secondProfile.id));
    await expectOk(await drivers.availability(secondDriverToken, true, true));

    const booked = await expectOk(await rides.book(flow.riderToken));
    const firstRequests = await expectOk(await rides.requests(flow.driverToken));
    const secondRequests = await expectOk(await rides.requests(secondDriverToken));
    expect(firstRequests.some((ride: any) => ride.id === booked.id)).toBe(true);
    expect(secondRequests.some((ride: any) => ride.id === booked.id)).toBe(true);

    const accepted = await expectOk(await rides.accept(flow.driverToken, booked.id));
    expect(accepted.status).toBe('ACCEPTED');
    await expectBadRequest(await rides.accept(secondDriverToken, booked.id), 'Ride is already accepted');
  });
});
