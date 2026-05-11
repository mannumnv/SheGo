import { APIResponse, expect } from '@playwright/test';

export async function expectOk(response: APIResponse): Promise<any> {
  expect(response.ok(), await response.text()).toBeTruthy();
  const body = await response.json();
  expect(body.success).toBe(true);
  return body.data;
}

export async function expectBadRequest(response: APIResponse, messagePart?: string): Promise<any> {
  expect(response.status()).toBeGreaterThanOrEqual(400);
  const body = await response.json().catch(() => ({}));
  if (messagePart) expect(JSON.stringify(body)).toContain(messagePart);
  return body;
}

export function expectNoSensitiveData(payload: unknown): void {
  const text = JSON.stringify(payload).toLowerCase();
  for (const forbidden of ['aadhaarnumber', 'aadhaar_encrypted', 'aadhaarencrypted', 'encrypted', 'guardianaadhaar', 'rideraadhaar']) {
    expect(text, `Sensitive field leaked: ${forbidden}`).not.toContain(forbidden);
  }
}

export function expectNoPublicS3Url(payload: unknown): void {
  const text = JSON.stringify(payload).toLowerCase();
  expect(text).not.toContain('s3.amazonaws.com');
  expect(text).not.toContain('amazonaws.com/');
}
