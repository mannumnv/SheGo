# Local Dev Fixes and Revert Notes

This file records temporary/local-development fixes made while running SheGo locally, why they were needed, and how to change them later when the real production setup is complete.

## 1. AWS S3 Presigner Region Startup Error

### Error

When running:

```bash
make backend
```

the backend failed with:

```text
Unable to load region from any of the providers in the chain
Region must be specified either via environment variable (AWS_REGION)
or system property (aws.region)
```

### Why It Happened

The backend creates an AWS S3 presigner bean for secure KYC/profile/SOS uploads.

AWS SDK needs a region to create the presigner. In production this usually comes from:

- ECS task environment variable
- EC2 instance metadata
- AWS profile
- `AWS_REGION`
- `aws.region`

On the local machine, no AWS region was configured, so Spring Boot failed during startup.

### Local Fix Applied

Added a default AWS region in:

```text
src/main/resources/application.yml
```

Current config:

```yaml
shego:
  aws:
    region: ${AWS_REGION:ap-south-1}
```

Updated:

```text
src/main/java/com/shego/config/AwsConfig.java
```

The S3 presigner now uses:

```java
S3Presigner.builder()
    .region(Region.of(region))
    .build();
```

Also added a default in:

```text
Makefile
```

```makefile
AWS_REGION ?= ap-south-1
```

### Should This Be Reverted Later?

Not necessarily. This is safe because it still allows production override:

```bash
AWS_REGION=ap-south-1
AWS_REGION=us-east-1
AWS_REGION=ap-southeast-1
```

The default only applies when no environment variable is provided.

### Production Setup Later

When AWS setup is complete, set the real region in the deployment environment:

For ECS task definition:

```text
AWS_REGION=ap-south-1
```

For EC2:

```bash
export AWS_REGION=ap-south-1
```

For Docker:

```bash
docker run \
  -e AWS_REGION=ap-south-1 \
  -e S3_BUCKET=shego-prod-private \
  shego-backend:latest
```

For local `.env`:

```text
AWS_REGION=ap-south-1
S3_BUCKET=shego-dev-private
```

### How To Remove the Local Default Later

If you want production to fail fast when `AWS_REGION` is missing, change:

```yaml
region: ${AWS_REGION:ap-south-1}
```

to:

```yaml
region: ${AWS_REGION}
```

Then remove this from `Makefile` if desired:

```makefile
AWS_REGION ?= ap-south-1
```

After that, every environment must explicitly provide `AWS_REGION`.

## 2. Java 21 vs Local Java 17

### Error

Initial local Maven build failed with:

```text
release version 21 not supported
```

### Why It Happened

The project is configured for Java 21, but local Maven was using Java 17.

The project requirement is still Java 21.

### Local Fix Applied

For local development only, Makefile uses:

```makefile
mvn -Djava.version=17 spring-boot:run
```

and:

```makefile
mvn -Djava.version=17 clean package -DskipTests
```

This lets the app run on the current machine.

### Production Setup Later
# Java 21 chalana ho to documented steps ye hain:
Install JDK 21 and make Maven use it:

```bash
export JAVA_HOME=$(/usr/libexec/java_home -v 21)
mvn -version
```

Confirm Maven shows Java 21.

### How To Revert Later

Once Maven uses Java 21, change Makefile from:

```makefile
mvn -Djava.version=17 spring-boot:run
```

to:

```makefile
mvn spring-boot:run
```

And change:

```makefile
mvn -Djava.version=17 clean package -DskipTests
```

to:

```makefile
mvn clean package -DskipTests
```

## 3. Database Connection Startup Error

### Error

Backend failed with:

```text
Unable to obtain connection from database
The connection attempt failed
```

### Why It Happened

PostgreSQL was not running or was not accessible when Spring Boot started.

### Local Fix Applied

Makefile was changed so:

```bash
make backend
```

automatically starts:

```bash
docker compose up -d postgres redis
```

before running the backend.

### Production Setup Later

In production:

- PostgreSQL will run on RDS.
- Redis will run on ElastiCache.
- Backend will receive:

```text
DB_URL
DB_USERNAME
DB_PASSWORD
REDIS_HOST
REDIS_PORT
```

No local Docker dependency is needed in production.

### How To Revert Later

If you do not want `make backend` to start Docker automatically, change:

```makefile
backend: deps
```

to:

```makefile
backend:
```

Then start dependencies manually with:

```bash
make deps
```

## Recommended Future Setup

When the real environment is ready:

1. Install and use JDK 21 locally.
2. Set real AWS credentials and `AWS_REGION`.
3. Set real `S3_BUCKET`.
4. Use RDS PostgreSQL and ElastiCache Redis in production.
5. Keep local defaults only for developer convenience.
6. Keep production environment explicit and fail-fast for missing secrets.

## AI Prompt To Revert Local Dev Workarounds Later

Use this prompt in a future AI/Codex session when the real production setup is ready:

```text
You are working in the SheGo repository.

Goal:
Revert or clean up local-development workarounds and make the backend/frontend setup production-ready.

Context:
The file `docs/LOCAL_DEV_FIXES_AND_REVERT_NOTES.md` documents temporary fixes that were added for local development:
1. Default AWS region fallback in `application.yml`.
2. Explicit S3Presigner region configuration in `AwsConfig`.
3. `AWS_REGION ?= ap-south-1` default in `Makefile`.
4. Java 17 Maven override in `Makefile`.
5. `make backend` automatically starting local Docker dependencies.

Tasks:
1. Inspect:
   - `src/main/resources/application.yml`
   - `src/main/java/com/shego/config/AwsConfig.java`
   - `Makefile`
   - `docs/AWS_DEPLOYMENT_GUIDE.md`
   - `README.md`

2. Confirm the production environment is ready:
   - JDK 21 is installed and Maven uses Java 21.
   - AWS credentials are configured.
   - `AWS_REGION` is provided by the environment.
   - `S3_BUCKET` is provided by the environment.
   - RDS PostgreSQL is available.
   - Redis/ElastiCache is available.
   - Required backend env vars are documented.

3. Remove Java 17 local override from Makefile.
   Change:
   `mvn -Djava.version=17 spring-boot:run`
   to:
   `mvn spring-boot:run`

   Change:
   `mvn -Djava.version=17 clean package -DskipTests`
   to:
   `mvn clean package -DskipTests`

4. Decide AWS region behavior:
   If production should fail fast when `AWS_REGION` is missing, change:
   `region: ${AWS_REGION:ap-south-1}`
   to:
   `region: ${AWS_REGION}`

   Also remove this Makefile default if present:
   `AWS_REGION ?= ap-south-1`

5. Decide local dependency behavior:
   If `make backend` should not auto-start Docker, change:
   `backend: deps`
   to:
   `backend:`

   Keep `make deps` available for local developers.

6. Update README:
   - Mention JDK 21 is required.
   - Mention required production env vars.
   - Mention how to run locally and in production.

7. Update this document:
   - Mark which workarounds were removed.
   - Keep a short note explaining why they were removed.

8. Run verification:
   - `mvn clean test`
   - `flutter analyze`
   - `flutter test`

Constraints:
- Do not remove existing working business logic.
- Do not change SheGo app rules.
- Vehicle types must remain only `SCOOTY` and `BIKE`.
- Do not add auto, car, taxi, or mixed-gender support.
- Preserve Docker and Flutter build commands.

Deliverables:
- Code changes.
- Updated README if needed.
- Updated docs.
- Verification results.
```

# make backend command flow:
Ye automatically pehle ye karega:
docker compose up -d postgres redis
Phir backend start karega:
mvn -Djava.version=17 spring-boot:run