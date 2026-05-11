import { test, expect } from '@playwright/test';
import { RideClient } from '../clients/rideClient';
import { auth } from '../clients/authClient';
import { createApprovedRiderAndDriver, requireAdmin } from '../utils/flow';
import { expectOk } from '../utils/assertions';

test.describe('Full SheGo ride flow', () => {
  test.beforeEach(() => requireAdmin());

  test('create users, approve, book, accept, arrive, start, complete, rate', async ({ request }) => {
    const rides = new RideClient(request);
    const flow = await createApprovedRiderAndDriver(request);

    const booked = await expectOk(await rides.book(flow.riderToken));
    const accepted = await expectOk(await rides.accept(flow.driverToken, booked.id));
    expect(accepted.status).toBe('ACCEPTED');

    await expectOk(await rides.arrive(flow.driverToken, booked.id));
    const riderView = await expectOk(await rides.get(flow.riderToken, booked.id));
    expect(riderView.startOtp).toBeTruthy();

    const started = await expectOk(await rides.start(flow.driverToken, booked.id, riderView.startOtp));
    expect(started.status).toBe('STARTED');

    const completed = await expectOk(await rides.complete(flow.driverToken, booked.id));
    expect(completed.status).toBe('COMPLETED');

    const rating = await expectOk(await request.post('/api/ratings', {
      headers: auth(flow.riderToken),
      data: {
        rideId: booked.id,
        ratedUserId: flow.driverUser.id,
        overallRating: 5,
        safetyRating: 5,
        comfortRating: 5,
        drivingBehaviorRating: 5,
        comments: 'Safe automated test ride',
        unsafeReported: false
      }
    }));
    expect(rating.overallRating).toBe(5);
  });
});
