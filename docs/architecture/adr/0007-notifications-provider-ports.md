# ADR-0007: Notification intents with consent-aware provider ports

- Status: Accepted (pending issue #3 final approval)
- Date: 2026-10-23

## Context
Notifications must survive provider outages, honor consent/opt-outs at send
time, avoid duplicates, and tell the truth about delivery state (PRD FR-NTF,
§7.7).

## Decision
Notification domain owns **intents** (purpose, recipients, content refs) and
**delivery attempts** (append-only, per channel). In-app is a first-class
channel; SMS/email/WhatsApp are provider adapters behind a Go port, enabled
per workspace configuration + consent evidence. A dispatcher job claims
intents (SKIP LOCKED), checks consent/suppression, sends via adapter, records
attempt state; retries with backoff up to `notifications.retry_cap` →
EXHAUSTED (terminal, staff-visible). Templates are versioned, bilingual
(English/Kiswahili per D-4 scope).

## Consequences
Provider outages degrade delivery, never lose intent; truthfulness is
testable; adapter differences (idempotency support) are encapsulated per
adapter with documented behavior.
