import { APIRequestContext } from '@playwright/test';
import { apiUrl, auth } from './authClient';
import { expectOk } from '../utils/assertions';

export class AdminClient {
  constructor(private readonly request: APIRequestContext, private readonly token: string) {}

  users() {
    return this.request.get(apiUrl('/api/admin/users'), { headers: auth(this.token) });
  }

  pendingDriverKyc() {
    return this.request.get(apiUrl('/api/admin/pending-driver-kyc'), { headers: auth(this.token) });
  }

  drivers(page = 0, size = 10) {
    return this.request.get(apiUrl(`/api/admin/drivers?page=${page}&size=${size}`), { headers: auth(this.token) });
  }

  driver(driverId: string) {
    return this.request.get(apiUrl(`/api/admin/drivers/${driverId}`), { headers: auth(this.token) });
  }

  pendingGuardianVerifications() {
    return this.request.get(apiUrl('/api/admin/pending-guardian-verifications'), { headers: auth(this.token) });
  }

  approveDriverVerification(driverId: string) {
    return this.request.post(apiUrl(`/api/admin/drivers/${driverId}/approve`), { headers: auth(this.token) });
  }

  rejectDriverVerification(driverId: string, reason = 'Rejected by automated test') {
    return this.request.post(apiUrl(`/api/admin/reject-driver-verification?driverId=${driverId}&reason=${encodeURIComponent(reason)}`), { headers: auth(this.token), data: {} });
  }

  rejectDriver(driverId: string, reason = 'Rejected by automated test') {
    return this.request.post(apiUrl(`/api/admin/drivers/${driverId}/reject`), { headers: auth(this.token), data: { reason } });
  }

  requestDriverResubmission(driverId: string, reason = 'Please upload clearer documents') {
    return this.request.post(apiUrl(`/api/admin/request-driver-resubmission?driverId=${driverId}&reason=${encodeURIComponent(reason)}`), { headers: auth(this.token), data: {} });
  }

  approveRiderVerification(riderId: string) {
    return this.request.post(apiUrl(`/api/admin/approve-rider-verification?riderId=${riderId}`), { headers: auth(this.token) });
  }

  rejectKyc(kycId: string, reason = 'Rejected by automated test') {
    return this.request.post(apiUrl(`/api/admin/kyc/${kycId}/reject`), { headers: auth(this.token), data: { reason } });
  }

  pendingKyc() {
    return this.request.get(apiUrl('/api/admin/kyc/pending'), { headers: auth(this.token) });
  }

  async approveRiderAndDriver(riderId: string, driverId: string) {
    await expectOk(await this.approveRiderVerification(riderId));
    await expectOk(await this.approveDriverVerification(driverId));
  }
}
