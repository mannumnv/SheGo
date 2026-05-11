import { APIRequestContext } from '@playwright/test';
import { auth } from './authClient';
import { pickup, drop } from '../fixtures/testData';

export class RideClient {
  constructor(private readonly request: APIRequestContext) {}

  estimate(token: string, vehicleType = 'SCOOTY') {
    return this.request.post('/api/rides/estimate', { headers: auth(token), data: { vehicleType, ...pickup, ...drop } });
  }

  book(token: string, vehicleType = 'SCOOTY') {
    return this.request.post('/api/rides/book', { headers: auth(token), data: { vehicleType, ...pickup, ...drop } });
  }

  accept(token: string, rideId: string) {
    return this.request.post(`/api/rides/${rideId}/accept`, { headers: auth(token), data: {} });
  }

  arrive(token: string, rideId: string) {
    return this.request.post(`/api/rides/${rideId}/arrive`, { headers: auth(token), data: {} });
  }

  start(token: string, rideId: string, otp: string) {
    return this.request.post(`/api/rides/${rideId}/start`, { headers: auth(token), data: { otp } });
  }

  complete(token: string, rideId: string) {
    return this.request.post(`/api/rides/${rideId}/complete`, { headers: auth(token), data: {} });
  }

  get(token: string, rideId: string) {
    return this.request.get(`/api/rides/${rideId}`, { headers: auth(token) });
  }
}
