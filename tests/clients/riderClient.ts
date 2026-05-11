import { APIRequestContext } from '@playwright/test';
import { apiUrl, auth } from './authClient';
import { expectOk } from '../utils/assertions';

export class RiderClient {
  constructor(private readonly request: APIRequestContext) {}

  signup(payload: Record<string, unknown>) {
    return this.request.post(apiUrl('/api/riders/signup'), { data: payload });
  }

  login(payload: { mobileNumber: string; password: string }) {
    return this.request.post(apiUrl('/api/riders/login'), { data: payload });
  }

  async signupToken(payload: Record<string, unknown>): Promise<string> {
    const data = await expectOk(await this.signup(payload));
    return data.accessToken;
  }

  profile(token: string) {
    return this.request.get(apiUrl('/api/riders/profile'), { headers: auth(token) });
  }

  verifyGuardian(token: string, payload: Record<string, unknown>) {
    return this.request.post(apiUrl('/api/riders/verify-guardian'), { headers: auth(token), data: payload });
  }
}
