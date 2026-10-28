# ADR-0011: OIDC identity provider — Keycloak, self-hosted

| | |
|---|---|
| Date | 2026-10-28 |
| Status | Accepted |
| Decides | PRD open decision D-2 (issue #3, ADR-0004 "Proposed" status) |

## Context

ADR-0004 standardized on OIDC with Keycloak as candidate, explicitly pending
D-2. Application code targets the OIDC standard (issuer discovery, JWKS
verification, ≤15-min token TTL, revocation-version checks per blueprint §7),
so the issuer is operational configuration, not a code commitment.

## Decision

Keycloak, self-hosted in staging and production; docker compose for local
development (shipped with the #4 identity workstream per
docs/local-development.md). The product owner authorized execution via the
Engineering Execution Mandate (2026-10-28), adopting the recommendation
recorded in PRD §11.

## Consequences

- #4 ships OIDC verification against a configurable issuer with a
  test-double issuer for the suite; no Keycloak dependency in unit/integration
  tests.
- Local compose (postgres + keycloak + minio) is the documented reproducible
  environment; sandbox delivery environments may substitute embedded
  PostgreSQL binaries (documented in docs/local-development.md).
- Reversal to any standards-compliant issuer (e.g., Auth0, Ory) is an ops
  configuration change, not a rewrite (per ADR-0004's design intent).
- Keycloak realm config (roles mirroring workspace capabilities, token TTL
  15 min) is operational documentation under #31/#28, not code.
