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
  unique indexes. Redis/Temporal deliberately deferred (ADR-0009).
- Append-only enforcement: application DB role lacks UPDATE/DELETE on
  payments, allocations, receipts, expenses, audit_events.

## Consequences
Strong integrity guarantees and one less system to operate; queue semantics
must be tested (visibility timeouts, retries, poison messages); BIGINT requires
discipline at API edges (serialize as strings per PRD).
