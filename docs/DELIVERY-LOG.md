# SharkEstate — Delivery Log (append-only)

Engineering delivery record. Each entry: date, issue/PR, decision or outcome,
evidence location. Newest entries at the bottom. Never rewrite history here;
corrections are new entries that reference the old ones.

---

## 2026-10-23 — Baseline audit (before this PR)

- Repository at commit `9edca8e`: Phase-0 docs only; no code, tests, or CI.
- 31 open issues (#1–#31); 0 PRs; only `main` existed (no `dev`).
- Dependency graph extracted from issue bodies; #2 identified as first
  executable issue (its dependency #1's direction is confirmed in-body).
- Conflict recorded: pre-existing `README.md`/`ARCHITECTURE.md`/`ROADMAP.md`
  and `docs/*` proposals assume a Next.js-fullstack stack, conflicting with
  the approved Go-backend baseline (master execution prompt + #3). Resolution
  in this PR: moved to `docs/proposals/phase0/` with a superseded banner.
- Toolchain: Go 1.23.4 installed (was absent); Node 24.21, bun 1.3.14 present;
  no local PostgreSQL server (escalated — required from #4 onward).

## 2026-10-23 — PR (issue #2) independent review round 1 and fixes

- Independent Staff Engineer review of `feat/2-bootstrap-governance`: verdict
  REQUEST_CHANGES — 2 blocking, 5 non-blocking findings. All addressed:
  1. [blocking] `dev` was not the repository default branch → default flipped
     to `dev` via admin API (PATCH /repos → default_branch=dev) and recorded.
  2. [blocking] Secret-scan gate command false-positived on prose and
     `.env.example` placeholders → replaced with value-based pattern and the
     actual run output recorded below.
  3. [non-blocking] pnpm → bun in the gate (toolchain standardization).
  4. [non-blocking] Commit `0584e00` authored as `z@container` — identity
     exception accepted and recorded here (history rewrite on a pushed branch
     would violate no-force-push governance). Standard identity going forward:
     `Roy-Wanyoike <57495194+Roy-Wanyoike@users.noreply.github.com>`.
  5. [non-blocking] `.gitignore` added to layout diagram.
  6. [non-blocking] Clone URL switched to HTTPS.
  7. [non-blocking] Unresolvable "master execution prompt" reference removed;
     issue #3 cited as sole in-repo architecture authority.
- Protection settings re-verified after review found the first API call
  silently coerced `required_approving_review_count` to 1 (misspelled request
  key). Re-set with correct field name; live force-push denial test against
  `dev` rejected by the protected-branch hook. Final verified state on both
  branches: approvals=0, dismiss_stale=true, force_push=false, deletions=false,
  linear=true, enforce_admins=true.
- Fixed gate run (value-based secret scan, this branch vs origin/dev): no
  matches (placeholders and prose do not match the pattern).

## 2026-10-23 — Issue #15 opened: PRD drafted on feat/15-prd

- docs/PRD.md v1.0.0-draft: vision/success measures, 6 personas, MVP boundary
  (incl. payment-model hard boundary), 10 FR domains with stable IDs and
  testable AC, permission matrix (6 roles), 7 state-transition tables,
  12 edge cases (mapped to test obligations), Africa-first platform-vs-country
  split, NFRs, open decisions D-1..D-5 (pilot country blocks #3/#5 detail).

## 2026-10-23 — Issue #15 PRD revision v1.0.1 (review round 1 addressed)

- Two independent reviews (staff engineer, QA) returned REQUEST_CHANGES with
  overlapping blocking findings on the v1.0.0 state machines and financial
  semantics. v1.0.1 resolves ALL blocking findings:
  - Invoice: OVERDUE became a derived flag (coexists with PARTIALLY_PAID);
    VOID reachable from DRAFT/ISSUED/PARTIALLY_PAID/PAID (allocations reversed
    first); DRAFT discard added; recompute rule ties state to allocations.
  - Payment: FAILED terminal except staff re-confirmation via verified
    statement evidence (late statement lines); REVERSED effects deterministic
    (corrective allocations, invoice recompute, receipt SUPERSEDED and hidden
    from tenant list); allocations restricted to CONFIRMED payments / non-VOID
    invoices; credit (overpayment) model added FR-PAY-08 + E-13.
  - Global error contract for all machines: invalid/guard-failed transition ->
    409 TRANSITION_INVALID, state unchanged, financial attempts audited.
  - Expenses promoted to minimal MVP domain FR-EXP-01..03 (statements now
    honestly reconcile to the minor unit).
  - Currency scope pinned: fixed per workspace at first financial record;
    statements per workspace; cross-workspace rollups out of scope; E-11
    expects per-currency breakdown (FX only as explicit recorded action).
  - Lease machine: DRAFT->CANCELLED, backdated EXPIRED renewal, holdover
    resolution, EXPIRING as real state with configurable window; E-09
    CLOSED->IN_PROGRESS reopen now legal (with work-order relink).
  - Permission matrix made mechanically testable: atomic capability legend,
    receipt issue/view split, payment record/confirm/reverse split, second-
    person cash verification policy, named policy keys for all footnoted
    cells, tenant report set enumerated (FR-RPT-06), cross-workspace 404
    convention; rows added for inspections and tasks.
  - Notification machine: EXHAUSTED terminal state, SUPPRESSED reachable at
    send-time; retry cap named policy.
  - Testability: aging buckets anchored to due date (0-30/31-60/61+), invoice
    numbering semantics (gaps permitted after VOID), quantified NFRs (p95,
    dataset shape, 2G profile 250kbps/500ms RTT), FR ACs de-subjectivized.
  - New edge cases E-13 (credit) and E-14 (receipt superseded by reversal).

## 2026-10-23 — Issue #15 PRD revision v1.0.2 (review round 2 addressed)

- Staff round 2: APPROVE (4 non-blocking one-liners). QA round 2:
  REQUEST_CHANGES on exactly one new blocking defect + 6 non-blocking.
- v1.0.2 fixes (all findings from both reviewers):
  - [QA N-1 blocking] Tasks row ADDED to §6 matrix (AA RCU(W), PM RCU(P),
    CT/CN RU(A)); Documents/media row added; CORRECTION to the v1.0.1 log
    entry below: that entry falsely claimed a tasks row existed in v1.0.1 —
    it did not; appended here per append-only policy.
  - Allocatable invoice states pinned to {ISSUED, PARTIALLY_PAID} (FR-PAY-02,
    §7.4); allocation to DRAFT/VOID/PAID rejected 409.
  - Reconciliation view now includes PENDING payments flagged
    awaiting-evidence/disputed (FR-PAY-05, harmonized with E-07).
  - Receipt content when zero allocations: auto-issued at confirmation, zero
    invoice lines, references lease/tenant (FR-PAY-04).
  - E-11 restated fail-closed (mixed-currency fixture not constructible).
  - Determinism nits: aging bucket boundary note (day 31 -> 31-60, day 61 ->
    61+); billing.late_fee_enabled marked reserved post-MVP (fails closed);
    access.revocation_notify default on; payments.second_person_verification
    defaults (cash on, electronic off); FR-LSE-02 normalization defined
    (E.164 phone, casefolded name).
  - Matrix editorial: footnote 3 reworded (reverse is AA-only, dual control);
    CT identity-doc cell cites ct.identity_doc_access; R-contact added to
    legend; AA granted activate/terminate/renew (W) on leases; PM Expenses
    cell gains RCU+submit.

## 2026-10-23 — Issue #15 PRD v1.0.2 approved by both reviewers; final editorial pass

- QA round-3 focused confirmation: APPROVE (all round-2 findings resolved).
- Staff round-2: APPROVE.
- Final editorial commit per reviewer instruction: domain verbs added to
  capability legend (submit/activate/terminate/renew); sign-off table updated
  with round verdicts. PO sign-off remains the open gate.

## 2026-10-23 — Issue #3 opened: architecture blueprint + ADRs on feat/3-architecture

- docs/architecture/ARCHITECTURE.md v0.9.0: system shape (Go modular monolith
  + Next.js 16 frontend + PostgreSQL), domain module map with boundary rules,
  entity relationships, workspace isolation + authz implementation contract,
  financial integrity implementation contract (BIGINT minor units, append-only
  via DB privileges, balance invariants, no-money-movement architecture test),
  regional/provider port boundaries, environments + SLOs + failure modes,
  STRIDE threat-model summary, deferred-infrastructure triggers.
- ADR-0001..0009 recorded (Nygard format). README links updated.
- Status: 0.9.0 draft — final approval gated on PO sign-off (PRD + D-1/D-2).

## 2026-10-23 — Issue #3 architecture v0.9.1 (staff review round 1 addressed)

- Independent staff review: REQUEST_CHANGES, 5 blocking findings — all fixed:
  1. Immutability scoped to business fields; lifecycle via guarded status
     paths; per-table DB privilege model spelled out (ADR-0003 + §5).
  2. Concurrent allocation: SELECT…FOR UPDATE on payment+invoice in
     deterministic order; lease activation guarded by partial unique index on
     (unit_id) WHERE status IN (ACTIVE, EXPIRING); races added to
     FIN-INVARIANTS.
  3. Revocation ≤60 s mechanized: per-request revocation-version check with
     ≤60 s-stale in-process cache; introspection for sensitive ops; revoke→401
     probe test (ADR-0004 + §7).
  4. ER boundary contract completed: Payment↔Tenancy (credit/unallocated),
     lease predecessor/successor chain, Property↔Expense(0..1 WorkOrder),
     deposit on lease, unit-without-building note.
  5. FX ConversionRecord ownership assigned to regional module; fail-closed
     CURRENCY_MISMATCH guard added to invariants.
- Non-blocking: queue failure-mode design (transactional enqueue, visibility
  lease, dead-letter), TSP server-side owner mapping, D-1 → planned ADR-0010,
  callback signature/replay protection requirement, invoice-gen SLO added.

## 2026-10-23 — Issue #3 architecture v0.9.2 (round-2 minor patches; staff APPROVE)

- Staff round 2: APPROVE. Minor patches folded per reviewer instruction:
  invoice DRAFT-window carve-out note in privilege model; EXPIRED-holdover
  primary-gate clarification for the activation index; regional module
  key-entities gains ConversionRecord; read-models-are-views note; ADR index
  header notes planned ADR-0010; probe-test status-code precision.

## 2026-10-26 — Issue #14 opened: quality gates foundation on docs/14-quality-gates

- Baseline state consumed: PRs #35/#36/#37/#38 merged (bootstrap, PRD v1.0.2,
  blueprint v0.9.2 + ADR-0001..0009, release to main). #3 engineering-approved;
  PO decisions pending: PRD sign-off, D-1 pilot country, D-2 identity provider.
  #14 is the first ungated deliverable (explicitly "starts with #2 and #3").
- `scripts/quality-gate.sh`: normative gate executor (G1 no-Actions, G2a no-.env,
  G2b value-based secret scan diff/full-tree, G3 markdown link check, G4 Go
  fmt/vet/test, G5 frontend install/lint/build/test, G6 govulncheck/bun audit,
  G7 migration rollback posture). Auto-activates per workstream; SKIP is loud.
- `docs/quality/TEST-STRATEGY.md` v0.1.0: test levels; named-suite registry
  (FIN-INVARIANTS, AUTHZ-MATRIX, WS-ISOLATION-IDOR, REPRODUCIBILITY, REDACTION,
  IDEMPOTENCY, A11Y-PERF, MIGRATION, NO-MONEY-MOVEMENT) with land-with issues;
  E-01..E-14 traceability; FR coverage rule + matrix template; budgets from
  PRD §10; test-data/privacy policy; gate-green criteria per PR type.
- `docs/quality/THREAT-REGISTER.md` v0.1.0: the "full register" ARCHITECTURE §8
  defers to — T-01..T-14 with mitigation/suite/owner/status; T-13 encodes the
  standing release blocker (no persistent customer data before #31 drill).
- `docs/quality/RELEASE-CHECKLIST.md` v0.1.0: dev→main promotion checklist,
  APPROVE/BLOCK verdict format, revert-default rollback policy.
- BRANCH-GOVERNANCE.md, local-development.md, README.md updated to reference
  the gate executor; command map expanded.
- Doc-drift finding: ARCHITECTURE §5 cites "PRD §14 suite FIN-INVARIANTS" but
  PRD v1.0.2 ends at §12; canonical suite definitions now live in
  docs/quality/TEST-STRATEGY.md (blueprint editorial fix → #3 follow-up).
- Status: issue #14 stays OPEN — gates + registry delivered; suites themselves
  are obligations attached to their owning issues (#4/#7/#8/#9/#10/#11/#12/#28/#31).
