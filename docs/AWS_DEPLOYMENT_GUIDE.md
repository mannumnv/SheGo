# SheGo AWS Deployment Guide

This guide deploys the SheGo Spring Boot backend with PostgreSQL, Redis, private S3 storage, and CloudWatch logging. Current ride support remains women-only `SCOOTY` and `BIKE`.

## AWS Services Needed

- Amazon VPC with public and private subnets
- Amazon RDS for PostgreSQL
- Amazon ElastiCache for Redis
- Amazon S3 for private KYC/profile/SOS files
- Amazon ECS Fargate or EC2 for the Spring Boot container
- Amazon ECR for backend Docker images
- AWS CloudWatch Logs
- AWS IAM roles and policies
- Optional: Application Load Balancer, Route 53, ACM TLS certificate

## RDS PostgreSQL

1. Open AWS RDS and create a PostgreSQL 16 database.
2. Use a private subnet group.
3. Set database name to `shego`.
4. Create a strong master username and password.
5. Disable public access for production.
6. Create a security group that allows inbound PostgreSQL `5432` only from the backend ECS/EC2 security group.
7. Copy the RDS endpoint for `DB_URL`.

Example JDBC URL:

```text
jdbc:postgresql://<rds-endpoint>:5432/shego
```

## S3 Bucket

1. Create a bucket such as `shego-prod-private`.
2. Keep Block Public Access enabled.
3. Enable bucket encryption with SSE-S3 or SSE-KMS.
4. Add lifecycle rules for temporary uploads and expired location/safety evidence if required by policy.
5. Give the backend task role permission for `s3:PutObject`, `s3:GetObject`, and `s3:DeleteObject` on the bucket.

KYC documents must be stored by private object key only. Never expose direct public S3 URLs. Admin/support review should use short-lived pre-signed download URLs from the backend.

## Redis

1. Create an ElastiCache Redis cluster in private subnets.
2. Allow inbound Redis `6379` only from the backend ECS/EC2 security group.
3. Use Redis for OTP rate limiting, OTP temporary storage, live driver locations, and short-lived sessions.

## ECS Fargate Deployment

1. Create an ECR repository named `shego-backend`.
2. Build and push the Docker image:

```bash
aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <account>.dkr.ecr.<region>.amazonaws.com
docker build -t shego-backend .
docker tag shego-backend:latest <account>.dkr.ecr.<region>.amazonaws.com/shego-backend:latest
docker push <account>.dkr.ecr.<region>.amazonaws.com/shego-backend:latest
```

3. Create an ECS cluster.
4. Create a Fargate task definition using the image from ECR.
5. Attach a task execution role for ECR and CloudWatch.
6. Attach an application task role for S3 access.
7. Configure container port `8080`.
8. Add an Application Load Balancer with HTTPS from ACM if exposing public APIs.

## EC2 Deployment Alternative

1. Launch an Amazon Linux EC2 instance.
2. Install Docker.
3. Pull the image from ECR.
4. Run the container with environment variables.
5. Use a security group that exposes only `80/443` publicly and keeps database/Redis private.

## Environment Variables

Set these in ECS task definition or EC2 runtime:

```text
PORT=8080
DB_URL=jdbc:postgresql://<rds-endpoint>:5432/shego
DB_USERNAME=<database-user>
DB_PASSWORD=<database-password>
REDIS_HOST=<elasticache-endpoint>
REDIS_PORT=6379
JWT_SECRET=<at-least-32-byte-secret>
SHEGO_DATA_ENCRYPTION_KEY=<strong-secret-for-aadhaar-encryption>
ACCESS_TOKEN_MINUTES=30
REFRESH_TOKEN_DAYS=30
S3_BUCKET=shego-prod-private
GOOGLE_MAPS_API_KEY=<google-maps-key>
```

Keep secrets in AWS Secrets Manager or SSM Parameter Store. Do not hardcode production secrets in task definitions or source code.

## CloudWatch Logs

1. Enable the `awslogs` log driver in the ECS task.
2. Use a group such as `/ecs/shego-backend`.
3. Set retention, for example 30 or 90 days.
4. Create alarms for high error rates, task restarts, CPU, memory, and database connection failures.

## Database Migrations

Flyway runs automatically when the backend starts. On first production deployment:

1. Confirm `spring.flyway.enabled=true`.
2. Start one backend task first.
3. Check CloudWatch logs for Flyway success.
4. Scale up backend tasks after migration succeeds.

For high-risk migrations, run a one-off ECS task before rolling out the main service.

## Flutter Web or Admin Dashboard

For Flutter web:

```bash
cd shego_flutter
flutter build web --dart-define=API_BASE_URL=https://api.shego.example.com
```

Deploy `build/web` to S3 static hosting behind CloudFront. Use ACM for TLS and Route 53 for DNS.

For a future React admin dashboard, deploy the static build the same way: S3 + CloudFront, with the backend API URL configured at build time.

## Security Groups

- ALB: inbound `443` from internet, outbound to backend service.
- Backend ECS/EC2: inbound `8080` only from ALB security group.
- RDS: inbound `5432` only from backend security group.
- Redis: inbound `6379` only from backend security group.
- No public inbound access to RDS or Redis.

## Production API Smoke Tests

After deployment:

1. Check health by calling an unauthenticated auth endpoint.
2. Register a rider and driver.
3. Upload KYC metadata with a private S3 key.
4. Approve KYC as admin.
5. Approve driver as admin.
6. Set driver online and available.
7. Estimate and book a `SCOOTY` or `BIKE` ride.
8. Accept, start with OTP, complete, rate the ride.
9. Trigger and resolve SOS.
10. Confirm WebSocket connection to `/ws/location`.

Example:

```bash
curl -X POST https://api.shego.example.com/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"mobileNumber":"9876543210","password":"secret123"}'
```

## Operational Notes

- Keep KYC documents private and encrypted.
- Rotate JWT secrets and database credentials using Secrets Manager.
- Configure retention for location data based on legal and product policy.
- Monitor SOS and complaint APIs with priority alerts.
- Do not add auto, car, taxi, or mixed-gender support without a product/security review.
