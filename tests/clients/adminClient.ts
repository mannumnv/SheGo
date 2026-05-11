import { APIRequestContext } from '@playwright/test';
import { auth } from './authClient';
import { expectOk } from '../utils/assertions';

export class AdminClient {
  constructor(private readonly request: APIRequestContext, private readonly token: string) {}

  users() {
    return this.request.get('/api/admin/users', { headers: auth(this.token) });
  }

  pendingDriverKyc() {
    return this.request.get('/api/admin/pending-driver-kyc', { headers: auth(this.token) });
  }

  pendingGuardianVerifications() {
    return this.request.get('/api/admin/pending-guardian-verifications', { headers: auth(this.token) });
  }

  approveDriverVerification(driverId: string) {
    return this.request.post(`/api/admin/approve-driver-verification?driverId=${driverId}`, { headers: auth(this.token) });
  }

  approveRiderVerification(riderId: string) {
    return this.request.post(`/api/admin/approve-rider-verification?riderId=${riderId}`, { headers: auth(this.token) });
  }

  rejectKyc(kycId: string, reason = 'Rejected by automated test') {
    return this.request.post(`/api/admin/kyc/${kycId}/reject`, { headers: auth(this.token), data: { reason } });
  }

  pendingKyc() {
    return this.request.get('/api/admin/kyc/pending', { headers: auth(this.token) });
  }

  async approveRiderAndDriver(riderId: string, driverId: string) {
    await expectOk(await this.approveRiderVerification(riderId));
    await expectOk(await this.approveDriverVerification(driverId));
  }
}
