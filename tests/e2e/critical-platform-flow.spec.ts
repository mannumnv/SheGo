import { test, expect } from '@playwright/test';
import { apiUrl, auth, AuthClient } from '../clients/authClient';
import { DriverClient } from '../clients/driverClient';
import { RideClient } from '../clients/rideClient';
import { adultFemaleDriver } from '../fixtures/testUsers';
import { createApprovedRiderAndDriver, requireAdmin, adminClient } from '../utils/flow';
import { expectBadRequest, expectOk } from '../utils/assertions';

const secondDriverDocs = {
  profilePhotoData: 'e2e-second-profile-photo',
  aadhaarDocumentData: 'e2e-second-aadhaar-photo',
  licenseDocumentData: 'e2e-second-license-photo',
  vehicleDocumentData: 'e2e-second-vehicle-photo',
  insuranceDocumentData: 'e2e-second-insurance-photo',
};

test.describe('Critical SheGo platform E2E flow', () => {
  test.beforeEach(() => requireAdmin());

  test('rider books, multiple drivers receive request, one accept locks ride, OTP/payment/rating/notifications work', async ({ request }) => {
    const rides = new RideClient(request);
    const drivers = new DriverClient(request);
    const authClient = new AuthClient(request);
    const admin = await adminClient(request);

    const flow = await createApprovedRiderAndDriver(request);

    const secondDriverPayload = adultFemaleDriver({
      fullName: 'SheGo Second Driver',
      profilePhotoStorageKey: null,
      selfieStorageKey: null,
      aadhaarStorageKey: null,
      licenseStorageKey: null,
      vehicleDocumentStorageKey: null,
      insuranceDocumentStorageKey: null,
    });
    const secondDriverToken = await drivers.signupToken(secondDriverPayload);
    const secondDriverProfile = await expectOk(await drivers.profile(secondDriverToken));
    await expectBadRequest(await drivers.availability(secondDriverToken, true, true), 'documents must be approved');
    await expectOk(await drivers.submitDocuments(secondDriverToken, secondDriverDocs));
    await expectOk(await admin.approveDriverVerification(secondDriverProfile.id));
    await expectOk(await drivers.availability(secondDriverToken, true, true));
    await expectOk(await drivers.location(secondDriverToken));

    const riderActiveOff = await expectOk(await request.put(apiUrl('/api/riders/active'), {
      headers: auth(flow.riderToken),
      data: { active: false },
    }));
    expect(riderActiveOff.active).toBe(false);
    await expectBadRequest(await rides.book(flow.riderToken), 'inactive');

    const riderActiveOn = await expectOk(await request.put(apiUrl('/api/riders/active'), {
      headers: auth(flow.riderToken),
      data: { active: true },
    }));
    expect(riderActiveOn.active).toBe(true);

    const estimate = await expectOk(await rides.estimate(flow.riderToken));
    expect(Number(estimate.distanceKm)).toBeGreaterThan(0);
    expect(Number(estimate.estimatedFare)).toBeGreaterThan(0);

    const booked = await expectOk(await rides.book(flow.riderToken));
    expect(booked.id).toBeTruthy();
    expect(booked.status).toBe('REQUESTED');

    const firstDriverRequests = await expectOk(await rides.requests(flow.driverToken));
    const secondDriverRequests = await expectOk(await rides.requests(secondDriverToken));
    expect(firstDriverRequests.some((ride: any) => ride.id === booked.id)).toBe(true);
    expect(secondDriverRequests.some((ride: any) => ride.id === booked.id)).toBe(true);

    const driverNotifications = await expectOk(await request.get(apiUrl('/api/notifications'), {
      headers: auth(flow.driverToken),
    }));
    expect(driverNotifications.some((item: any) => item.title === 'New ride request received' && item.targetId === booked.id)).toBe(true);

    const accepted = await expectOk(await rides.accept(flow.driverToken, booked.id));
    expect(accepted.status).toBe('ACCEPTED');
    expect(accepted.driverName).toBeTruthy();
    expect(accepted.id).toBe(booked.id);

    await expectBadRequest(await rides.accept(secondDriverToken, booked.id), 'already accepted');

    const riderAcceptedView = await expectOk(await rides.get(flow.riderToken, booked.id));
    expect(riderAcceptedView.status).toBe('ACCEPTED');
    expect(riderAcceptedView.id).toBe(booked.id);
    expect(riderAcceptedView.driverName).toBeTruthy();

    const driverAcceptedView = await expectOk(await rides.get(flow.driverToken, booked.id));
    expect(driverAcceptedView.status).toBe('ACCEPTED');
    expect(driverAcceptedView.id).toBe(booked.id);

    const riderNotifications = await expectOk(await request.get(apiUrl('/api/notifications'), {
      headers: auth(flow.riderToken),
    }));
    expect(riderNotifications.some((item: any) => item.title === 'Driver assigned' && item.targetId === booked.id)).toBe(true);

    const arrived = await expectOk(await rides.arrive(flow.driverToken, booked.id));
    expect(arrived.status).toBe('DRIVER_REACHED');
    const riderOtpView = await expectOk(await rides.get(flow.riderToken, booked.id));
    expect(riderOtpView.startOtp).toMatch(/^\d{4}$/);

    await expectBadRequest(await rides.start(flow.driverToken, booked.id, '0000'), 'Invalid ride start OTP');
    const started = await expectOk(await rides.start(flow.driverToken, booked.id, riderOtpView.startOtp));
    expect(started.status).toBe('STARTED');

    const payment = await expectOk(await request.post(apiUrl('/api/payments/initiate'), {
      headers: auth(flow.riderToken),
      data: { rideId: booked.id, amount: 175, method: 'CASH' },
    }));
    expect(payment.rideId).toBe(booked.id);
    expect(payment.invoiceNumber).toContain('SHEGO-');

    const completed = await expectOk(await rides.complete(flow.driverToken, booked.id));
    expect(completed.status).toBe('COMPLETED');

    const invoice = await expectOk(await request.get(apiUrl(`/api/payments/ride/${booked.id}/invoice`), {
      headers: auth(flow.riderToken),
    }));
    expect(invoice.rideId).toBe(booked.id);
    expect(invoice.invoiceNumber).toBe(payment.invoiceNumber);

    const rating = await expectOk(await request.post(apiUrl('/api/ratings'), {
      headers: auth(flow.riderToken),
      data: {
        rideId: booked.id,
        ratedUserId: flow.driverUser.id,
        overallRating: 5,
        safetyRating: 5,
        comfortRating: 5,
        drivingBehaviorRating: 5,
        comments: 'End-to-end SheGo ride was safe',
        unsafeReported: false,
      },
    }));
    expect(rating.overallRating).toBe(5);

    const history = await expectOk(await request.get(apiUrl('/api/rides/history'), {
      headers: auth(flow.riderToken),
    }));
    expect(history.some((ride: any) => ride.id === booked.id && ride.status === 'COMPLETED')).toBe(true);

    const secondDriverFinalProfile = await expectOk(await drivers.profile(secondDriverToken));
    expect(secondDriverFinalProfile.available).toBe(true);

    const me = await expectOk(await authClient.me(flow.riderToken));
    expect(me.roles).toContain('RIDER');

    const missingRideId = '00000000-0000-4000-8000-000000000099';
    await expectBadRequest(await rides.get(flow.riderToken, missingRideId), 'Ride not found');
  });
});
