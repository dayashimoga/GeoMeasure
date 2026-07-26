# Known Issues

- **Docker Desktop Engine**: Docker Desktop must be running with Linux containers enabled for `build-docker.ps1` to execute. If the Docker daemon is not running, the script will fail at the `docker compose build` step.
- **Widget Tests on Non-Device**: Widget tests for DashboardPage run against the MissingPluginException fallback path since no native platform channel is available in test runners.
