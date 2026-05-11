import { APIRequestContext } from '@playwright/test';
import { apiUrl, auth } from './authClient';
import { pickup, drop } from '../fixtures/testData';

export class RideClient {
  constructor(private readonly request: APIRequestContext) {}

  estimate(token: string, vehicleType = 'SCOOTY') {
    return this.request.post(apiUrl('/api/rides/estimate'), { headers: auth(token), data: { vehicleType, ...pickup, ...drop } });
  }

  book(token: string, vehicleType = 'SCOOTY') {
    return this.request.post(apiUrl('/api/rides/book'), { headers: auth(token), data: { vehicleType, ...pickup, ...drop } });
  }

  accept(token: string, rideId: string) {
    return this.request.post(apiUrl(`/api/rides/${rideId}/accept`), { headers: auth(token), data: {} });
  }

  arrive(token: string, rideId: string) {
    return this.request.post(apiUrl(`/api/rides/${rideId}/arrive`), { headers: auth(token), data: {} });
  }

  start(token: string, rideId: string, otp: string) {
    return this.request.post(apiUrl(`/api/rides/${rideId}/start`), { headers: auth(token), data: { otp } });
  }

  complete(token: string, rideId: string) {
    return this.request.post(apiUrl(`/api/rides/${rideId}/complete`), { headers: auth(token), data: {} });
  }

  get(token: string, rideId: string) {
    return this.request.get(apiUrl(`/api/rides/${rideId}`), { headers: auth(token) });
  }
}
