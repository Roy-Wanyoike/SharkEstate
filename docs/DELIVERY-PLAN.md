# SharkEstate — Delivery Plan (Phase-1 audit, issue inventory)

| | |
|---|---|
| Date | 2026-10-28 |
| Trigger | Engineering Execution Mandate (product owner): resolve all pending issues, verified testing, production readiness |
| Baseline | dev @ a40c6dd — governance (#2), PRD v1.0.2 (#15), blueprint v0.9.2 + ADR-0001..0009 (#3), quality-gates foundation (#14/PR #39) |

## Audit result

33 open issues (#1–#34, #14 foundation merged but open). No product code
exists yet; every open feature issue is **not-started**, none is broken.
Untracked defects found by inspection (fixed or tracked here):

- **U-1 (fixed in this PR):** ARCHITECTURE §5 cited "PRD §14 suite
  FIN-INVARIANTS"; PRD v1.0.2 ends at §12. Canonical suite definitions live
  in docs/quality/TEST-STRATEGY.md (first recorded in DELIVERY-LOG 2026-10-26).
- **U-2 (environment, not repo defect):** delivery sandbox lacks Go/PostgreSQL
  until provisioned per session (delivery log 2026-10-23). Reproducible local
  env (compose) ships with #4.
- **U-3 (fixed):** ADR-0004/0011 status pending D-2; ADR-0010 planned — both
  resolved by product-owner decisions recorded in this PR.

No duplicate issues found. #16's child issues (#17–#24) are correctly scoped
post-MVP; no overlap with MVP issues detected.

## Issue inventory (priority order — dependency spine)

| Priority | Issue | Title (owner: Principal role) | Depends on | This-quarter status |
|---|---|---|---|---|
| P0 | #3, #15 | Architecture + PRD final approval (Staff Eng + PO) | — | **closed by this PR** (ADR-0010/0011 + sign-off) |
| P0 | #4 | IDENTITY: workspaces, membership, RBAC, audit (Backend Principal) | #2, #3 | **in progress** |
| P0 | #5 | REGION: country profiles, money, provider ports (Backend Principal) | #3 | next after #4 (schema sequence) |
| P1 | #6 | PORTFOLIO: properties, buildings, units (Backend Principal) | #4, #5 | queued |
| P1 | #7 | TENANCY: parties, leases, lifecycle (Backend Principal) | #4, #6 | queued |
| P1 | #8 | RENT: schedules, invoices, arrears (Backend Principal) | #5, #7 | queued |
| P1 | #9 | PAYMENTS: record, allocate, reconcile (Backend Principal) | #5, #8; D-3 credentials for adapter | queued |
| P2 | #10 | MAINTENANCE (Backend Principal) | #4, #6, #7 | queued |
| P2 | #11 | WORKFLOW: reminders, notifications, tasks (Backend Principal) | #4, #7 | queued |
| P2 | #12 | REPORTING (Backend Principal) | #8, #9 | queued |
| P2 | #13 | TENANT-UX portal (Frontend Principal) | #4, #8, #12 | queued (web/ scaffold with this) |
| P2 | #28 | MOBILE & UX FOUNDATION (Frontend Principal) | #13 | queued |
| P3 | #14 | QUALITY gates (Principal QA) | #2, #3 | foundation merged; closes when suites run on real scope |
| P3 | #31 | PLATFORM OPERATIONS (SRE Principal) | #3 | runbooks; hard gate: backup drill before customer data (T-13) |
| Deferred (post-MVP per #16) | #17–#24 | Deposits, utilities, expenses+, leasing, estate security, integrations, portability, analytics | per #16 | not started — do not pull into MVP |
| Deferred (post-MVP per #16) | #25–#27, #29, #30, #32–#34 | Accounting, disputes, assets, messaging ops, tax discovery, onboarding, commercial | per #16/#30 | #30 is a discovery gate before any Kenya tax behavior (T-14) |

## Parallelism rules applied

- Backend modules are developed in schema-migration order (#4 → #5 → #6…):
  parallel branches would collide on migration sequence and shared platform
  code; therefore sequential merges on the spine.
- Frontend (#13/#28) may parallelize against a frozen /v1 contract slice once
  #4/#5 merge (OpenAPI-first per ADR-0006).
- Every PR: branch from dev, local gate green before PR (mandate §5), PR to
  dev with `Refs #N`, review + QA evidence per PR template, squash-merge,
  issue closed only after verification on dev (repo governance — auto-close
  keywords are deliberately not used; mandate's "where appropriate" defers to
  BRANCH-GOVERNANCE.md).

## Known standing deviations (documented, not hidden)

1. **No GitHub Actions** — repository billing constraint (#2). CI-equivalent
   is the local gate + `GATE_FULL=1` release scan (quality-gate.sh); this is
   the repo's recorded control, not a gap introduced now.
2. **Single-operator review** — 0-required-approvals exception with mandatory
   evidence (BRANCH-GOVERNANCE.md). Escalates to 1 required approval when a
   second reviewer account exists.
3. **MVP money boundary** — payments are recorded/allocated/reconciled; no
   initiation/custody/settlement (PRD §3.3, NO-MONEY-MOVEMENT suite).
