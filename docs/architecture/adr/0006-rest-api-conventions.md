# ADR-0006: Versioned REST /v1, OpenAPI 3.1 spec-first, PRD-aligned error contract

- Status: Accepted (pending issue #3 final approval)
- Date: 2026-10-23

## Context
Multiple clients (back office, tenant portal, future partner integrations #22)
and QA need a stable, testable contract; the PRD defines specific error
semantics (409 TRANSITION_INVALID/guard codes, 404 cross-workspace convention).

## Decision
- REST under `/api/v1`; **OpenAPI 3.1 spec-first** — the spec is committed,
  handlers are generated/validated against it, and contract tests run in the
  local gate.
- Error body: `{ "error": { "code": string, "message": string, "fieldErrors"?: {} } }`
  with PRD codes (`TRANSITION_INVALID`, `UNIT_OCCUPIED`, `INVOICE_VOID`,
  `VALIDATION_ERROR`, `UNAUTHENTICATED`, `FORBIDDEN`, `NOT_FOUND`, `RATE_LIMITED`).
- Cross-workspace misses are `404` (indistinguishable — PRD E-12).
- Money serialized as strings of minor units; dates ISO-8601 UTC; timezone
  rendering client-side per workspace locale.
- Cursor pagination (`cursor`, `limit` ≤ 100) on all collections; no unbounded
  queries (row-limit audit in #14).

## Consequences
Contract tests catch drift before review; webhooks (#22) will version
separately; some verbosity vs GraphQL — accepted for contract stability.
