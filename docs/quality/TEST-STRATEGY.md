# SharkEstate — Test Strategy & Quality Gates

| | |
|---|---|
| Version | 0.1.0 (foundation — suite registry & traceability; suites implement as workstreams land) |
| Issue | [#14 QUALITY](https://github.com/Roy-Wanyoike/SharkEstate/issues/14) |
| Depends on | [PRD](../PRD.md) v1.0.2 · [ARCHITECTURE](../architecture/ARCHITECTURE.md) v0.9.2 · [BRANCH-GOVERNANCE](../BRANCH-GOVERNANCE.md) |
| Executor | `scripts/quality-gate.sh` (normative; run from repo root before every PR) |

## 1. Purpose and authority

Issue #14 defines the quality gates for a financial and personal-data system.
This document is the **registry of named test suites and traceability
obligations** that feature PRs must satisfy; it never gets bypassed, only
extended. A suite listed here with status *obligation-open* is a promise
attached to a specific issue — that issue cannot close without it.

> **Editorial drift note (found during this PR's cross-check):**
> `docs/architecture/ARCHITECTURE.md` §5 cites "PRD §14 suite
> FIN-INVARIANTS", but PRD v1.0.2 ends at §12. The canonical definitions of
> the named suites live **here**, not in the PRD. A blueprint editorial fix
> belongs to a #3 follow-up; recorded in `docs/DELIVERY-LOG.md`.

## 2. Test levels

| Level | Runner | Scope | Required for |
|---|---|---|---|
| Unit | `go test ./...` / `bun test` | Domain logic in isolation (state machines, guards, money math) | every code PR |
| Integration | `go test -tags=integration ./...` against disposable PostgreSQL | Real DB behavior: transactions, constraints, partial unique indexes, queue semantics, migrations | every backend PR touching DB or transactions |
| API contract | OpenAPI 3.1 spec-first validation (ADR-0006) | Request/response shapes, error codes match PRD §7/§8 contract | every endpoint PR |
| Authorization | `AUTHZ-MATRIX` + `WS-ISOLATION-IDOR` suites | PRD §6 permission matrix cell-by-cell; cross-workspace 404 convention | every authenticated surface |
| Property-based | `FIN-INVARIANTS` generators | Financial invariants hold across randomized operation sequences, not just scripted cases | payments/billing/expenses PRs |
| End-to-end | Journey smoke (Playwright) | Persona journeys from PRD §4: onboarding → lease → invoice → payment → receipt | release gate, per milestone |
| Performance | Budget harness (PRD §10 dataset) | p95 budgets, row-limit audit, no unbounded queries | dashboards, statements, invoice runs |
| Accessibility | axe-core + keyboard walkthrough | WCAG 2.1 AA on portal surfaces (PRD §10) | every UI PR touching portal surfaces |

## 3. Local quality gates

Executed by `scripts/quality-gate.sh`; policy in
[BRANCH-GOVERNANCE.md](../BRANCH-GOVERNANCE.md). Gates auto-activate as
code lands — a SKIP is a loud, explicit deferral, never a silent pass.

| Gate | Checks | Status |
|---|---|---|
| G1 | No GitHub Actions workflow files (repository constraint) | active |
| G2a | No `.env*` tracked besides `.env.example` | active |
| G2b | Value-based secret scan (diff vs `origin/dev`, or full tree) | active |
| G3 | Relative markdown links resolve | active |
| G4 | Go: `gofmt` clean, `go vet`, `go test ./...` | pending #4 |
| G5 | Frontend: `bun install --frozen-lockfile`, lint, build, test | pending web scaffold |
| G6a/b | Dependency scanning: `govulncheck` (Go), `bun audit` (frontend) | pending #4 / web scaffold |
| G7 | Every migration has `.down.sql` or in-file `ROLLBACK POSTURE` | pending #4 |

Gate rule: **any FAIL blocks the PR; SKIP is recorded in the PR body.**
Secret-scan exceptions (e.g., a redacted fixture) must be explained in the PR
body — the scan itself is never weakened for convenience.

## 4. Named suites (obligation registry)

| Suite | Scope (must-hold assertions) | Maps to | Lands with | Status |
|---|---|---|---|---|
| **FIN-INVARIANTS** | invoice state ⇔ Σ surviving allocations; Σ allocations ≤ payment; credit = Σ confirmed non-reversed − Σ surviving allocations (per lease); `CURRENCY_MISMATCH` fail-closed guard (E-11); concurrent allocation — two racing allocations, exactly one commits, deterministic `FOR UPDATE` order; concurrent lease activation — partial unique index + derived occupancy gate, loser gets `409 UNIT_OCCUPIED` (E-05); reversal determinism — corrective allocations, receipt → SUPERSEDED, invoice recompute (E-14) | PRD §7.2–7.4, E-01/E-05/E-13/E-14; ARCHITECTURE §5 | #8 (billing) + #9 (payments), schema base from #4 | obligation-open |
| **AUTHZ-MATRIX** | Every cell of PRD §6 exercised as a capability probe: allowed role succeeds, every other role denied with the matrix's error semantics; second-person cash verification enforced (dual control); revocation probe — revoke access, probe until `401`, assert ≤ 60 s (E-10); pre-revocation sensitive reads audit-logged | PRD §6, E-10; ARCHITECTURE §4/§7 | #4 (policy engine + first cells), extended per module | obligation-open |
| **WS-ISOLATION-IDOR** | For every workspace-scoped route: user of workspace A guesses workspace B resource IDs/URLs → `404` (indistinguishable), attempt audit-logged (rate-limited per E-12); jobs/webhooks re-check scope server-side | PRD E-12; ARCHITECTURE §4 | #4 (convention + harness), extended per module | obligation-open |
| **REPRODUCIBILITY** | Every displayed number equals a query on source records: dashboard == query equality tests; statements reconcile to minor units; arrears aging buckets anchored to due date (0-30/31-60/61+, boundary days 31→31-60, 61→61+) | PRD §10 auditability; ARCHITECTURE §2 reporting | #12 | obligation-open |
| **REDACTION** | No personal data, tokens, or money values in log lines, spans, error messages, or trace attributes (assertions over structured output); retention config keys present (`retention.<category>_days`) even before values ship | PRD §10 privacy; ARCHITECTURE §7 | #4 (logging foundation), extended per module | obligation-open |
| **IDEMPOTENCY** | Scheduled jobs run-twice without duplicate effects; webhook duplicate delivery returns original result (E-02); transactional enqueue — job row commits atomically with business change; visibility-timeout reclaim after crashed worker; poison message → dead-letter visible to staff with alerting | PRD E-02/E-04/E-08; ARCHITECTURE §7 queue semantics | #11, first consumers #8 | obligation-open |
| **A11Y-PERF** | axe audit clean on portal surfaces; keyboard-complete flows; critical tenant/caretaker screens < 200 KB; 250 kbps / 500 ms RTT profile passes; retry-safe submissions with visible pending/error states | PRD §10; #28 scope | #28 | obligation-open |
| **MIGRATION** | Migrations apply cleanly on fresh DB and on a copy of pilot-shaped data; rollback posture documented (G7); no migration holds locks incompatible with the 300 ms/800 ms SLOs without a rehearsed plan | PRD §10; ARCHITECTURE §7 | #4 onward | obligation-open |
| **NO-MONEY-MOVEMENT** | Architecture test asserts the provider port exposes record/reconcile only: no payout/transfer/initiate symbols in the built binary; provider-boundary code review recorded per adapter PR | PRD §3.3, FR-PAY-07; ARCHITECTURE §5 | #9 (first provider adapter) | obligation-open |

**Register rule:** adding a module PR that touches scope in this table
without adding its suite tests is a review-blocking defect.

## 5. Edge-case traceability (PRD §8 → suites)

Every PRD edge case is a **must-be test case**. Owner = the PR that makes the
scenario constructible.

| Edge case | Suite | Owning issue |
|---|---|---|
| E-01 partial payment lifecycle | FIN-INVARIANTS | #8/#9 |
| E-02 duplicate provider callback | IDEMPOTENCY + FIN-INVARIANTS | #9 |
| E-03 unmatched confirmed payment | FIN-INVARIANTS (+ reconciliation view in #12) | #9 |
| E-04 arrears escalation ladder (+3/+7/+14) | IDEMPOTENCY (job) + REDACTION (no PII in notifications) | #8/#11 |
| E-05 concurrent lease activation race | FIN-INVARIANTS | #7 (leases) — schema guard from #4/#5 |
| E-06 renewal predecessor/successor chain | FIN-INVARIANTS (chain integrity) + API contract | #7 |
| E-07 disputed payment, audited dispute note | FIN-INVARIANTS + WS-ISOLATION-IDOR (note visibility) | #9 |
| E-08 failed SMS retry with suppression re-check | IDEMPOTENCY | #11 |
| E-09 reopened repair, work-order relink | API contract + AUTHZ-MATRIX (CT/CN cells) | #10 |
| E-10 revocation ≤ 60 s + audit + notify task | AUTHZ-MATRIX | #4 |
| E-11 mixed-currency sums rejected fail-closed | FIN-INVARIANTS | #5 (currency guard) |
| E-12 cross-workspace 404 convention | WS-ISOLATION-IDOR | #4 |
| E-13 overpayment credit, never auto-applied | FIN-INVARIANTS | #9 |
| E-14 receipt superseded by reversal | FIN-INVARIANTS | #9 |

## 6. FR coverage rule

Every `FR-*` requirement's acceptance criteria must map to at least one
automated test ID before its owning issue closes. The coverage matrix below
is appended per module PR (one row per FR; test IDs named
`<SUITE>-<module>-<nnn>`).

| FR | AC summary | Test ID(s) | Status |
|---|---|---|---|
| *(template row — extend per module PR)* | | | |

## 7. Performance & accessibility budgets (from PRD §10)

- Dataset baseline: 50 units, 12 months history (~600 invoices, ~1,800
  payments, ~200 maintenance records); numbers are p95.
- API reads < 300 ms, writes < 800 ms; dashboards < 3 s; statements < 5 min;
  invoice generation for 50 leases < 60 s.
- Portal critical paths < 200 KB per screen at 250 kbps / 500 ms RTT.
- WCAG 2.1 AA; keyboard-complete; screen-reader labels; axe in local gate
  once UI exists (#28).

Budgets are enforced by the A11Y-PERF suite and, for query budgets, a
`row-limit audit` test asserting no unbounded queries (pagination/streaming
everywhere).

## 8. Test data & privacy policy

- Fixtures are synthetic; **no real personal data in tests, seeds, or logs**.
- Kenya-profile fixture data is only seeded after ADR-0010 (D-1 sign-off);
  until then fixtures use the platform-neutral profile.
- Identity-document and condition-photo fixtures live in the private-storage
  contract (ADR-0008) with scoped, expiring access — never in the repo.
- A deliberate secret-scan exception (redacted fixture) must be explained in
  the PR body and is re-examined at release review.

## 9. Gate-green criteria per PR type

| PR type | Required |
|---|---|
| Docs-only | G1–G3 green (what this PR demonstrates) |
| Backend feature | G1–G4, G6a, G7 green; suites for touched scope added & green |
| Frontend feature | G1–G3, G5, G6b green; A11Y-PERF for touched surfaces |
| Money-touching | All of the above for its stack **plus** FIN-INVARIANTS + NO-MONEY-MOVEMENT extensions, idempotency evidence, failure-path tests (CONTRIBUTING rule 7) |
| Release (dev→main) | Full green on dev tip + [RELEASE-CHECKLIST](./RELEASE-CHECKLIST.md) completed |
