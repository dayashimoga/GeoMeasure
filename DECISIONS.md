# Architecture Decision Records (ADR)

## ADR-001: Clean Architecture & Feature-Based Modularization
- **Context**: Need high maintainability, testability, and clear separation between platform sensors and measurement domain logic.
- **Decision**: Adopt Clean Architecture (Presentation, Domain, Data, Platform, Infrastructure) organized by feature modules (`capability_detection`, `measurement_engine`).
- **Consequences**: Enables 100% pure unit testing of domain calculations without native UI dependencies.

## ADR-002: Dockerized Development & CI Execution
- **Context**: Ensure reproducible builds and tests across developer workstations and CI runners.
- **Decision**: Provide Dockerfile and Docker Compose configurations for instant containerized test/build runs.
