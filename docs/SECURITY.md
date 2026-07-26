# Security

## Secure Storage

`HiveSecureStorage` in `lib/core/security/secure_storage.dart`:
- **Encryption**: AES-256 via `HiveAesCipher`
- **Encoding**: Base64 layer over encrypted values
- **Interface**: `SecureStorageService` (read, write, delete, deleteAll, containsKey)

> **Production note**: The current encryption key is a deterministic dev key. For production, generate a random 32-byte key and store it in the platform keychain (iOS Keychain / Android Keystore).

## Secrets Management

- **No secrets in VCS**: CI pipeline includes secret scanning (grep for hardcoded API keys, passwords, tokens)
- **Feature flags**: Sensitive features (AR, AI, cloud sync) disabled by default in `AppConfig`
- **Firebase**: Auth credentials configured via platform-specific config files (`google-services.json`, `GoogleService-Info.plist`)

## Permissions

Minimum necessary runtime permissions:

| Permission | Purpose | Required |
|-----------|---------|----------|
| Location | GPS measurement | When using GPS modes |
| Camera | Image capture, AR, photogrammetry | When using camera features |
| Storage | Export file saving | When exporting |

Managed via `permission_handler` package with graceful fallbacks.

## CI Security Checks

1. **Secret scanning**: Automated in GitHub Actions — scans `.dart`, `.yaml`, `.json` for credential patterns
2. **Dependency audit**: `flutter pub deps --no-dev` run on every CI build
3. **Format enforcement**: `dart format --set-exit-if-changed .` prevents unreviewed code

## Compliance Notes

| Standard | Status |
|----------|--------|
| OWASP MASVS L1 | Partially addressed (encrypted storage, no hardcoded secrets) |
| Certificate pinning | Not implemented |
| Obfuscation | Available via `flutter build apk --obfuscate --split-debug-info=./` |
| ProGuard/R8 | Android default configuration |
