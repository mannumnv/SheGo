import { APIRequestContext } from '@playwright/test';
import { expectOk } from '../utils/assertions';

export class AuthClient {
  constructor(private readonly request: APIRequestContext) {}

  async register(payload: Record<string, unknown>) {
    const response = await this.request.post(apiUrl('/api/auth/register'), { data: payload });
    return { response, data: response.ok() ? await response.json() : undefined };
  }

  async login(mobileNumber: string, password: string) {
    const response = await this.request.post(apiUrl('/api/auth/login'), { data: { mobileNumber, password } });
    return { response, data: response.ok() ? await response.json() : undefined };
  }

  async loginToken(mobileNumber: string, password: string): Promise<string> {
    const data = await expectOk(await this.request.post(apiUrl('/api/auth/login'), { data: { mobileNumber, password } }));
    return data.accessToken;
  }

  async me(token: string) {
    return this.request.get(apiUrl('/api/users/me'), { headers: auth(token) });
  }
}

export function auth(token: string) {
  return { Authorization: `Bearer ${token}` };
}

export function apiUrl(path: string) {
  if (path.startsWith('http')) return path;
  const baseUrl = (process.env.BASE_URL ?? 'http://localhost:8080')
    .replace('http://localhost:', 'http://127.0.0.1:')
    .replace('https://localhost:', 'https://127.0.0.1:');
  return `${baseUrl.replace(/\/$/, '')}${path}`;
}
