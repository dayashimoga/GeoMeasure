# ============================================================
# GeoMeasure Docker Build Environment
# Supports: lint, test, format, web build, and Android APK/AAB
# ============================================================

# Stage 1: Flutter + Android SDK base image
FROM ghcr.io/cirrusci/flutter:3.22.0 AS flutter-base

# Accept Android SDK licenses
RUN yes | flutter doctor --android-licenses 2>/dev/null || true

# Pre-warm pub cache
WORKDIR /app
COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

# Stage 2: Full build context
FROM flutter-base AS builder

COPY . .

# Ensure dependencies are resolved
RUN flutter pub get

# Default: run test suite
CMD ["flutter", "test", "--coverage"]

# ============================================================
# Usage (via docker-compose or directly):
#
#   Lint:    docker compose run app-analyze
#   Test:    docker compose run app-test
#   Format:  docker compose run app-format
#   Web:     docker compose run app-build-web
#   APK:     docker compose run app-build-apk
#   AAB:     docker compose run app-build-aab
#   All:     docker compose run app-ci
# ============================================================
