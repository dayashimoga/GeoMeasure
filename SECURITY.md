# Security & Compliance Policy

- **Zero Secret Commits**: No API keys, credentials, or secrets are stored in version control.
- **Data Encryption**: All local persistent data stored via encrypted Hive/SQLite engines.
- **Permissions**: Minimum necessary runtime permissions requested with explicit fallbacks.
- **Dependency Auditing**: Security scanning automated in CI/CD pipeline via GitHub Actions.
