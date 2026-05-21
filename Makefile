API_BASE_URL ?= http://localhost:8080
AWS_REGION ?= ap-south-1
FLUTTER_DIR := shego_flutter
IMAGE_NAME ?= shego-backend
IMAGE_TAG ?= latest

.PHONY: help deps backend frontend backend-build docker-build docker-run e2e flutter-web flutter-apk flutter-android-bundle stop

help:
	@echo "SheGo simple commands:"
	@echo "  make deps                    Start PostgreSQL and Redis"
	@echo "  make backend                 Run Spring Boot backend locally"
	@echo "  make frontend                Run Flutter app in Chrome"
	@echo "  make backend-build           Build backend jar"
	@echo "  make docker-build            Build backend Docker image"
	@echo "  make docker-run              Run backend Docker image"
	@echo "  make e2e                     Run Playwright API/E2E tests"
	@echo "  make flutter-web             Build Flutter web app"
	@echo "  make flutter-apk             Build Android APK"
	@echo "  make flutter-android-bundle  Build Android Play Store bundle"
	@echo "  make stop                    Stop Docker services"
	@echo ""
	@echo "Note: backend uses clean + Java 17 override for this Mac because Maven is currently on Java 17."
	@echo "If class file version error comes, run: mvn clean && make backend"

deps:
	docker compose up -d postgres redis

backend: deps
	# clean removes stale Java 21 compiled classes before running on local Java 17.
	@set -a; [ ! -f .env ] || . ./.env; set +a; AWS_REGION=$${AWS_REGION:-$(AWS_REGION)} mvn -Djava.version=17 clean spring-boot:run

frontend:
	@set -a; [ ! -f .env ] || . ./.env; set +a; cd $(FLUTTER_DIR) && flutter pub get && flutter run -d chrome --dart-define=API_BASE_URL=$${API_BASE_URL:-$(API_BASE_URL)}

# Backend ka .jar build karega.
backend-build:
	@set -a; [ ! -f .env ] || . ./.env; set +a; AWS_REGION=$${AWS_REGION:-$(AWS_REGION)} mvn -Djava.version=17 clean package -DskipTests

# Backend Docker image banayega:
docker-build:
	docker build -t $(IMAGE_NAME):$(IMAGE_TAG) .

# Docker image run karega, .env file se environment variables lega.
docker-run:
	docker run --rm -p 8080:8080 --env-file .env $(IMAGE_NAME):$(IMAGE_TAG)

e2e:
	@cd tests && npx playwright test

# Flutter web production build banayega.
flutter-web:
	@set -a; [ ! -f .env ] || . ./.env; set +a; cd $(FLUTTER_DIR) && flutter pub get && flutter build web --dart-define=API_BASE_URL=$${API_BASE_URL:-$(API_BASE_URL)}

# Android APK build karega.
flutter-apk:
	@set -a; [ ! -f .env ] || . ./.env; set +a; cd $(FLUTTER_DIR) && flutter pub get && flutter build apk --release --dart-define=API_BASE_URL=$${API_BASE_URL:-$(API_BASE_URL)}

# Play Store ke liye Android App Bundle build karega.
flutter-android-bundle:
	@set -a; [ ! -f .env ] || . ./.env; set +a; cd $(FLUTTER_DIR) && flutter pub get && flutter build appbundle --release --dart-define=API_BASE_URL=$${API_BASE_URL:-$(API_BASE_URL)}

stop:
	docker compose down
