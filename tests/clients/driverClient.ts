import { APIRequestContext } from '@playwright/test';
import { auth } from './authClient';
import { expectOk } from '../utils/assertions';

export class DriverClient {
  constructor(private readonly request: APIRequestContext) {}

  signup(payload: Record<string, unknown>) {
    return this.request.post('/api/drivers/signup', { data: payload });
  }

  login(payload: { mobileNumber: string; password: string }) {
    return this.request.post('/api/drivers/login', { data: payload });
  }

  async signupToken(payload: Record<string, unknown>): Promise<string> {
    const data = await expectOk(await this.signup(payload));
    return data.accessToken;
  }

  profile(token: string) {
    return this.request.get('/api/drivers/profile', { headers: auth(token) });
  }

  uploadKyc(token: string, payload: Record<string, unknown>) {
    return this.request.post('/api/drivers/upload-kyc', { headers: auth(token), data: payload });
  }

  availability(token: string, available = true, online = true) {
    return this.request.put('/api/drivers/availability', { headers: auth(token), data: { available, online } });
  }

  location(token: string, latitude = 28.6139, longitude = 77.209) {
    return this.request.put('/api/drivers/location', { headers: auth(token), data: { latitude, longitude } });
  }
}
