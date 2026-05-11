import { test, expect } from '@playwright/test';
import { RideClient } from '../clients/rideClient';
import { createApprovedRiderAndDriver, requireAdmin } from '../utils/flow';
import { expectBadRequest, expectOk } from '../utils/assertions';

test.describe('Ride OTP start APIs', () => {
  test.beforeEach(() => requireAdmin());

  test('driver marks arrival, wrong OTP is rejected, correct OTP starts ride', async ({ request }) => {
    const rides = new RideClient(request);
    const flow = await createApprovedRiderAndDriver(request);
    const booked = await expectOk(await rides.book(flow.riderToken));
    await expectOk(await rides.accept(flow.driverToken, booked.id));

    const arrivedDriverView = await expectOk(await rides.arrive(flow.driverToken, booked.id));
    expect(arrivedDriverView.status).toBe('DRIVER_REACHED');
    expect(arrivedDriverView.startOtp).toBeFalsy();

    const riderView = await expectOk(await rides.get(flow.riderToken, booked.id));
    expect(riderView.status).toBe('DRIVER_REACHED');
    expect(riderView.startOtp).toMatch(/^\d{4}$/);

    await expectBadRequest(await rides.start(flow.driverToken, booked.id, '0000'), 'Invalid ride start OTP');
    const afterWrongOtp = await expectOk(await rides.get(flow.riderToken, booked.id));
    expect(afterWrongOtp.status).toBe('DRIVER_REACHED');

    const started = await expectOk(await rides.start(flow.driverToken, booked.id, riderView.startOtp));
    expect(['STARTED', 'RUNNING']).toContain(started.status);
    expect(started.startedAt).toBeTruthy();
  });
});
