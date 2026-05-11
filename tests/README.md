# SheGo Playwright API and E2E Tests

This suite verifies SheGo backend APIs with Playwright `APIRequestContext` and TypeScript.

## Setup

```bash
npm install
```

Create `.env` in the repo root:

```text
BASE_URL=http://localhost:8080
ADMIN_MOBILE=
ADMIN_PASSWORD=
```

Admin-dependent tests are skipped automatically when `ADMIN_MOBILE` or `ADMIN_PASSWORD` is missing.

## Run

```bash
npx playwright test
npx playwright test tests/api
npx playwright test tests/e2e
npx playwright show-report
```

## Notes

- Tests use dynamic mobile numbers to avoid duplicate conflicts.
- Flutter/app code must never connect directly to PostgreSQL, Redis, or S3; tests only call Spring Boot REST APIs.
- KYC tests assert that responses do not expose Aadhaar, encrypted fields, or public S3 URLs.
- Full ride flow needs an admin user that can approve rider/driver verification.
