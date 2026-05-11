import { APIRequestContext } from '@playwright/test';
import { apiUrl, auth } from './authClient';
import { storageKey } from '../utils/randomData';

export class KycClient {
  constructor(private readonly request: APIRequestContext) {}

  upload(token: string, documentType: string, key = storageKey('kyc', `${documentType.toLowerCase()}.jpg`)) {
    return this.request.post(apiUrl('/api/kyc/upload'), {
      headers: auth(token),
      data: {
        documentType,
        privateStorageKey: key,
        maskedDocumentNumber: 'XXXX-XXXX-1234'
      }
    });
  }

  status(token: string) {
    return this.request.get(apiUrl('/api/kyc/status'), { headers: auth(token) });
  }
}
