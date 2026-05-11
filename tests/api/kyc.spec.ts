import { test, expect } from '@playwright/test';
import { RiderClient } from '../clients/riderClient';
import { KycClient } from '../clients/kycClient';
import { adultFemaleRider } from '../fixtures/testUsers';
import { expectNoPublicS3Url, expectNoSensitiveData, expectOk } from '../utils/assertions';

test.describe('KYC APIs', () => {
  test('uploads Aadhaar, license, vehicle, insurance, and selfie metadata safely', async ({ request }) => {
    const rider = adultFemaleRider();
    const riders = new RiderClient(request);
    const kyc = new KycClient(request);
    const token = await riders.signupToken(rider);

    for (const documentType of ['AADHAAR', 'DRIVING_LICENSE', 'VEHICLE_DOCUMENT', 'INSURANCE', 'SELFIE']) {
      const uploaded = await expectOk(await kyc.upload(token, documentType));
      expect(uploaded.documentType).toBe(documentType);
      expect(uploaded.status).toBe('PENDING');
      expectNoSensitiveData(uploaded);
      expectNoPublicS3Url(uploaded);
    }

    const status = await expectOk(await kyc.status(token));
    expect(status.length).toBeGreaterThanOrEqual(5);
    expectNoSensitiveData(status);
    expectNoPublicS3Url(status);
  });
});
