FROM ghcr.io/cirrusci/flutter:3.22.0

WORKDIR /app

COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

COPY . .

CMD ["flutter", "test"]
