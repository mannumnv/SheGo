import { APIRequestContext } from '@playwright/test';
import { auth } from './authClient';
import { storageKey } from '../utils/randomData';

export class KycClient {
  constructor(private readonly request: APIRequestContext) {}

  upload(token: string, documentType: string, key = storageKey('kyc', `${documentType.toLowerCase()}.jpg`)) {
    return this.request.post('/api/kyc/upload', {
      headers: auth(token),
      data: {
        documentType,
        privateStorageKey: key,
        maskedDocumentNumber: 'XXXX-XXXX-1234'
      }
    });
  }

  status(token: string) {
    return this.request.get('/api/kyc/status', { headers: auth(token) });
  }
}
