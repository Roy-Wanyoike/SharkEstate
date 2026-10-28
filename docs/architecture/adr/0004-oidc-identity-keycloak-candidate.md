# ADR-0004: OIDC identity; Keycloak candidate (D-2 pending)

- Status: Accepted via [ADR-0011](./0011-oidc-keycloak-self-hosted.md) (product-owner decision D-2, 2026-10-28)
- Date: 2026-10-23

## Context
Multi-role staff, landlords, tenants, contractors need authentication with
workspace-scoped authorization, immediate-ish revocation (PRD: ≤ 60 s cached
tokens), and no local password store in MVP.

## Decision
Backend consumes **OIDC** from a configurable issuer. **Keycloak is the
candidate** (self-hosted; compose for local/staging). Tokens short-lived;
workspace/role claims refreshed at token expiry; revocation via short TTL +
introspection on sensitive endpoints. Tenant portal activation is an
application-level flow (link + OTP to registered phone) on top of OIDC
accounts (FR-IDW-08).

## Consequences
No password storage/rotation burden; depends on a second runtime (Keycloak)
with its own ops runbook (#31); OTP delivery depends on the notifications
module (SMS adapter). If D-2 selects an alternative OIDC provider, only this
ADR's issuer-ops section changes — application code targets the OIDC standard.
