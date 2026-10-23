# SharkEstate — Architecture Blueprint

| | |
|---|---|
| Version | 0.9.0 (draft for review — final approval gated on PO sign-off of PRD + D-1/D-2) |
| Status | In review (issue #3) |
| Depends on | [PRD](../PRD.md) v1.0.2 (merged; PO sign-off pending), issue #1 confirmed decisions |
| Decision records | [adr/](./adr/) — ADR-0001 … ADR-0009 |

## 1. System shape

**Modular monolith in Go**, one deployable backend, one Next.js frontend,
PostgreSQL as the single authoritative store. Domain modules communicate
through explicit service interfaces (ports); no cross-module table access.
Extraction into services is explicitly deferred — boundaries are kept clean so
it remains possible without rewrites.

```
                    ┌────────────────────────────────────────────┐
   Next.js 16       │                Go Backend                  │
  ┌───────────┐     │  ┌──────────────────────────────────────┐  │
  │ Web (TS,  │ REST│  │            API layer (v1)            │  │
  │ shadcn/ui)├────►│  │  authz middleware · OpenAPI-validated │  │
  └───────────┘ /v1 │  └──────────────┬───────────────────────┘  │
                    │  ┌──────────────▼───────────────────────┐  │
   Tenant portal ──►│  │            Domain modules            │  │
   (same web app)   │  │ identity · portfolio · parties/lease │  │
                    │  │ billing · payments · expenses        │  │
   Provider         │  │ maintenance · notifications · report │  │
   webhooks ───────►│  │ regional                             │  │
                    │  └───────┬──────────────────┬───────────┘  │
   Cron/scheduler ─►│  jobs    │                  │ ports:       │
                    │  ┌───────▼───────┐  ┌───────▼───────────┐  │
                    │  │  PostgreSQL   │  │ object storage ·  │  │
                    │  │ (authoritative│  │ payment rails ·   │  │
                    │  │  + job queue) │  │ SMS/email/WhatsApp│  │
                    │  └───────────────┘  └───────────────────┘  │
                    └────────────────────────────────────────────┘
```

## 2. Domain boundaries (module map)

| Module | Owns | Key entities | Notes |
|---|---|---|---|
| **identity** | workspaces, users, memberships, roles, delegation, audit events, tenant portal activation | Workspace, User, Membership, Delegation, AuditEvent | deny-by-default authz policy engine; every module calls it |
| **regional** | country profiles, currency config, provider adapter registry, policy switches | CountryProfile, ProviderConfig, PolicySet | data-driven; no country logic in code (PRD FR-REG) |
| **portfolio** | properties, buildings, units, occupancy derivation, media links | Property, Building, Unit | occupancy derived from parties/leases state |
| **parties** | tenant/landlord/contractor profiles, duplicate detection | Party (Tenant, Owner, Contractor), DuplicateCandidate | profiles persistent & portable across tenancies |
| **leases** | tenancies, leases, amendments, renewals, activation guards | Tenancy, Lease, LeaseAmendment | state machine PRD §7.1; concurrency-safe activation |
| **billing** | rent schedules, invoices, line items, arrears aging | RentSchedule, Invoice, InvoiceItem | schedule→invoice idempotent per period; overdue = derived flag |
| **payments** | payment records, confirmations, allocations, credit, receipts, reconciliation | Payment, Allocation, Receipt, DisputeNote | append-only; allocation only from CONFIRMED → {ISSUED, PARTIALLY_PAID} |
| **expenses** | expense records, approvals, reversals | Expense, ExpenseApproval | minimal MVP set (FR-EXP) |
| **maintenance** | requests, inspections, work orders, vendors/contractors, approval routing | MaintenanceRequest, Inspection, WorkOrder | threshold routing per policy |
| **notifications** | intents, channel attempts, consent/suppression, staff tasks | NotificationIntent, DeliveryAttempt, Task | in-app first; provider adapters behind ports |
| **reporting** | dashboards, statements, arrears, occupancy, exports | read models/views | reproducibility invariant: dashboard == query on source records |

**Boundary rules:** modules expose service interfaces + typed events; HTTP
handlers and other modules may not touch foreign tables; cross-module
workflows (e.g., lease activation → schedule generation → notification) are
orchestrated in the owning module via explicit calls or transactional events —
never via shared database writes.

## 3. Entity relationships (core)

```
Workspace 1─* Membership *─1 User
Workspace 1─* Property 1─* Building 1─* Unit
Property *─* Party(Owner)          (ownership; management = Delegation)
Unit 1─* Tenancy *─* Party(Tenant) (LeaseTenant)
Tenancy 1─* Invoice 1─* InvoiceItem
Payment 1─* Allocation *─1 Invoice
Payment 1─1 Receipt (0..1)         (issued on confirmation; superseded on reversal)
Tenancy 1─* MaintenanceRequest → WorkOrder → Expense
AuditEvent: polymorphic ref (entityType, entityId) + actor + action
```

(Complete field-level schema ships as versioned SQL migrations with the first
implementation PR — issue #4/#5; this diagram is the boundary contract.)

## 4. Tenancy isolation & authorization (PRD §6 implementation)

- **Single database, workspace-scoped rows.** Every domain table carries
  `workspace_id`; the data layer injects the workspace predicate from the
  request context — no repository may accept a query without a scope.
- Authorization = **policy engine** (RBAC + property scoping + record
  ownership), enforced in the API layer *and* re-checked inside domain
  commands that are entry points for jobs/webhooks.
- Cross-workspace denies return `404` (PRD E-12); invalid state transitions
  return `409 TRANSITION_INVALID` / guard codes (PRD §7 contract).
- Sensitive reads (identity documents, payment records, owner financials) are
  audit-logged at the service boundary.
- Mechanically tested: PRD §6 matrix → AUTHZ-MATRIX suite (#14), plus
  WS-ISOLATION-IDOR probes.

## 5. Financial integrity (implementation contract)

- **Money = `BIGINT` minor units** in PostgreSQL (no floats anywhere);
  currency per workspace, locked at first financial record (PRD FR-REG-02).
- **Append-only financial records:** payments/allocations/receipts/expenses
  are never updated or deleted; corrections are reversal/corrective records.
  Enforced by DB privileges (application role lacks UPDATE/DELETE on these
  tables) + architecture tests asserting absence of mutation paths.
- **Balance invariants** (property-based tests, PRD §14 suite FIN-INVARIANTS):
  invoice state ⇔ Σ surviving allocations; Σ allocations ≤ payment; credit =
  Σ confirmed non-reversed − Σ surviving allocations (per lease).
- **Transactions & idempotency:** every multi-record state change runs in one
  PostgreSQL transaction; webhook/idempotency keys unique-indexed; duplicate
  delivery returns the original result (PRD E-02).
- **No money movement** (PRD §3.3): the provider port exposes
  record/reconcile adapters only; an architecture test greps the built binary
  for payout/transfer symbols (FR-PAY-07).

## 6. Regional & integration boundaries

- Country profile data (currency precision, timezone, formats, policy
  switches, escalation defaults, provider availability) lives in
  **regional** module tables + config, never in shared code (PRD FR-REG-04).
- Payment/SMS/email/WhatsApp providers implement Go **ports** (interfaces)
  with per-country adapter registry; unavailable providers are disabled at
  the API surface (FR-REG-03).
- Pilot country selection (D-1) affects only seeded profile data + which
  adapters ship configured — recorded in ADR-0009 when decided.

## 7. Deployment, environments, operations (summary; SLOs below)

| Environment | Purpose | Notes |
|---|---|---|
| local | development | docker compose: postgres, minio (S3), mock providers; Keycloak via compose (D-2) |
| staging | integration + QA gate | pilot-country profile; sandbox provider credentials |
| production | pilot tenants | protected config; backups per issue #31 |

- Migrations: versioned SQL (golang-migrate), forward-only with documented
  rollback posture per PRD/issue #14; migrations run in CI-equivalent local
  gate before any PR merge.
- Observability: OpenTelemetry (traces, metrics, logs) with **redaction
  rules** — no personal data, tokens, or money values in spans/log lines
  (tests assert redaction). Health/readiness endpoints per module.
- SLOs (initial, per PRD §10 baselines): API p95 < 300 ms (reads) / < 800 ms
  (writes) at pilot scale; dashboard endpoints < 3 s p95; notification intent
  durability 100% (intent survives any provider outage); backup RPO ≤ 24 h,
  RTO ≤ 4 h (issue #31 formalizes).

**Failure modes & recovery (top 5):** provider callback loss → reconciliation
sweep job + manual re-confirmation path (PRD §7.3); duplicate webhook delivery
→ idempotency keys; DB failover → PITR backups + runbook (#31); bad migration
→ forward-fix policy + pre-merge staging rehearsal; secret leakage → rotation
runbook + scanning gate (#14).

## 8. Threat model (STRIDE summary — full register tracked in #14)

| Threat | Vector | Mitigation (tested) |
|---|---|---|
| Spoofing | stolen OIDC tokens | short token TTL + revocation propagation ≤ 60 s (FR-IDW-03); provider-signed webhooks |
| Tampering | financial record mutation | append-only DB privileges + reversal-only corrections; audit chain |
| Repudiation | disputed actions on money | audit events on every financial transition attempt incl. denials |
| Info disclosure | cross-workspace access (IDOR) | scope injection + 404 convention + isolation suite; private object storage with expiring signed URLs |
| Denial of service | webhook floods / enumeration | rate limits + attempt audit (E-12); bounded queues |
| Elevation of privilege | role self-grant, AI approval paths | role changes admin-only + audit; AI/automation never holds approval capabilities (assertion test, FR-MNT-04/EXP-02) |

Privacy: data minimization (PRD), redaction tests, retention config keys from
day one (values pending legal input — PRD §11), tenant export consent-scoped
when #23 lands.

## 9. What is explicitly deferred (with trigger conditions)

| Deferred | Trigger to revisit |
|---|---|
| Redis caching | measured read-path p95 misses (dashboards) after profiling |
| Temporal (durable workflows) | > 3 long-running multi-day workflows with human steps (beyond notifications/arrears ladder) |
| NATS JetStream / event mesh | > 1 service extraction or fan-out beyond in-process events |
| Microservices split | team > ~8 engineers on one deployable causing real contention |
| Read replicas / reporting store | statement generation p95 breach at 10× pilot scale |

## 10. ADR index

| ADR | Decision |
|---|---|
| [ADR-0001](./adr/0001-record-architecture-decisions.md) | Record architecture decisions (Nygard format) |
| [ADR-0002](./adr/0002-modular-monolith-go.md) | Go modular monolith with hexagonal module boundaries |
| [ADR-0003](./adr/0003-postgresql-authoritative-store.md) | PostgreSQL authoritative store; BIGINT minor units; golang-migrate; Postgres-backed job queue first |
| [ADR-0004](./adr/0004-oidc-identity-keycloak-candidate.md) | OIDC identity; Keycloak candidate pending D-2 |
| [ADR-0005](./adr/0005-nextjs-frontend.md) | Next.js 16 + TypeScript + shadcn/ui frontend on versioned REST |
| [ADR-0006](./adr/0006-rest-api-conventions.md) | Versioned REST /v1, OpenAPI 3.1 spec-first, PRD-aligned error contract |
| [ADR-0007](./adr/0007-notifications-provider-ports.md) | Notification intents with consent-aware provider ports |
| [ADR-0008](./adr/0008-private-object-storage.md) | Private S3-compatible object storage with scoped presigned access |
| [ADR-0009](./adr/0009-deferred-infrastructure.md) | Deferred/rejected infrastructure (Redis, Temporal, NATS, microservices) with trigger conditions |
