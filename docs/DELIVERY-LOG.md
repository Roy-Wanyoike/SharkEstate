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
