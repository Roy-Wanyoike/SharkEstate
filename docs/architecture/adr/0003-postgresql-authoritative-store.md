# ADR-0003: PostgreSQL authoritative store; BIGINT minor units; golang-migrate; Postgres-backed job queue

- Status: Accepted (pending issue #3 final approval)
- Date: 2026-10-23

## Context
Financial records require strict transactions, concurrency control, and
auditability. Schedules (invoicing, arrears ladder, lease expiries) need
durable background processing. Money must never be floats; currencies vary in
precision (KES 2dp, XOF 0dp).

## Decision
- **PostgreSQL** is the single authoritative store for application and
  financial records.
- All money stored as **BIGINT minor units** + currency code; formatting at
  the edge via country precision.
- Migrations: versioned SQL via **golang-migrate**, forward-only with a
  documented rollback posture per migration (down scripts where safe,
  compensating-migration notes otherwise).
- Background jobs: durable **PostgreSQL-backed queue** (SKIP LOCKED) with
  idempotency keys and at-least-once delivery + exactly-once effects via
  unique indexes. Queue semantics: transactional enqueue (job row commits in
  the same transaction as the business change), claim-lease with visibility
  timeout for crashed workers, poison messages → staff-visible dead-letter
  with alerting. Redis/Temporal deliberately deferred (ADR-0009).
- Immutability enforcement (business-field level, aligned with PRD §7 state
  machines): application DB role has **no DELETE** on financial tables and
  **no UPDATE on business-field columns** (amount, currency, method, payer
  reference, evidence, receipt document, allocation amounts); lifecycle status
  columns change only via domain commands inside transactions. Audit table:
  no UPDATE/DELETE at any layer (API pre-checks return 409 per FR-IDW-07).

## Consequences
Strong integrity guarantees and one less system to operate; queue semantics
must be tested (visibility timeouts, retries, poison messages); BIGINT requires
discipline at API edges (serialize as strings per PRD).
