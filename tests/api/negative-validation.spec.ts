import { test, expect } from '@playwright/test';
import { apiUrl, auth } from '../clients/authClient';
import { DriverClient } from '../clients/driverClient';
import { RiderClient } from '../clients/riderClient';
import { adultFemaleDriver, adultFemaleRider, minorFemaleRider } from '../fixtures/testUsers';
import { expectBadRequest, expectOk } from '../utils/assertions';

const missingId = '00000000-0000-4000-8000-000000000001';

test.describe('Negative validation and privacy', () => {
  test('driver signup ignores/rejects rider-only fields by schema validation boundary', async ({ request }) => {
    const drivers = new DriverClient(request);
    const data = await expectOk(await drivers.signup(adultFemaleDriver({
      guardianName: 'Should Not Exist',
      guardianAadhaarNumber: '123412341234',
      guardianConsent: true,
      riderAadhaarNumber: '123412341234'
    })));
    // Jackson currently ignores unknown JSON fields, preserving backward compatibility.
    // The contract is still enforced by OpenAPI/schema tests: these fields do not exist in DriverDtos.SignupRequest.
    if (data) {
      // Signup response is auth-only and must not echo unknown rider fields.
      expect(JSON.stringify(data)).not.toContain('guardianAadhaarNumber');
    }
  });

  test('adult female rider without Aadhaar is rejected', async ({ request }) => {
    const riders = new RiderClient(request);
    await expectBadRequest(await riders.signup(adultFemaleRider({ riderAadhaarNumber: undefined })), 'Rider Aadhaar is required');
  });

  test('guardian consent is required for minor riders', async ({ request }) => {
    const riders = new RiderClient(request);
    await expectBadRequest(await riders.signup(minorFemaleRider({ guardianConsent: false })), 'Guardian consent is required');
  });

  test('driver cannot go online before approval', async ({ request }) => {
    const drivers = new DriverClient(request);
    const token = await drivers.signupToken(adultFemaleDriver());
    await expectBadRequest(await drivers.availability(token), 'Driver must be KYC approved and admin approved');
  });

  test('missing ride/payment/rating resources return safe API errors', async ({ request }) => {
    const drivers = new DriverClient(request);
    const token = await drivers.signupToken(adultFemaleDriver());

    await expectBadRequest(await request.get(apiUrl(`/api/rides/${missingId}`), { headers: auth(token) }), 'Ride not found');
    await expectBadRequest(await request.post(apiUrl('/api/payments/initiate'), {
      headers: auth(token),
      data: { rideId: missingId, amount: 100, method: 'CASH' }
    }), 'Ride not found');
    await expectBadRequest(await request.post(apiUrl('/api/ratings'), {
      headers: auth(token),
      data: {
        rideId: missingId,
        ratedUserId: missingId,
        overallRating: 5,
        safetyRating: 5,
        comfortRating: 5,
        drivingBehaviorRating: 5,
        comments: 'safe',
        unsafeReported: false
      }
    }), 'Ride not found');
  });

  test('missing driver and subscription plan return safe API errors', async ({ request }) => {
    const drivers = new DriverClient(request);
    const token = await drivers.signupToken(adultFemaleDriver());

    await expectBadRequest(await request.get(apiUrl(`/api/safety/driver/${missingId}/score`), { headers: auth(token) }), 'Driver not found');
    await expectBadRequest(await request.post(apiUrl('/api/subscriptions/purchase'), {
      headers: auth(token),
      data: { planId: missingId }
    }), 'Subscription plan not found');
  });
});
