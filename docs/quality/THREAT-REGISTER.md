# SharkEstate — Threat Register

| | |
|---|---|
| Version | 0.1.0 |
| Issue | [#14 QUALITY](https://github.com/Roy-Wanyoike/SharkEstate/issues/14) |
| Source | [ARCHITECTURE](../architecture/ARCHITECTURE.md) §8 STRIDE summary (this register is the "full register" that §8 defers to) |

## Process

- The register is reviewed at **every release gate** (see
  [RELEASE-CHECKLIST](./RELEASE-CHECKLIST.md)); a new threat surface ships
  only with its register row added **in the same PR**.
- Status values: `design` (mitigation designed, tests pending),
  `tested` (suite evidence exists), `accepted` (documented risk acceptance by
  product owner — never granted by engineering alone).
- "Owning issue" is where the mitigation's test evidence must first exist.

## Register

| ID | STRIDE | Threat | Asset / vector | Mitigation (tested) | Suite | Owning issue | Status |
|---|---|---|---|---|---|---|---|
| T-01 | Spoofing | Stolen or replayed OIDC access tokens | Workspace data via API | Token TTL ≤ 15 min; per-request revocation-version check with ≤ 60 s cache bound; introspection for sensitive ops | AUTHZ-MATRIX (revocation probe) | #4 | design |
| T-02 | Spoofing | Forged provider payment callbacks (M-Pesa Daraja or successor adapter) | Payment confirmation → false receipts | Signature verification + replay protection mandatory before a callback may confirm; unverified callbacks recorded, never confirm | IDEMPOTENCY + FIN-INVARIANTS | #9 | design |
| T-03 | Tampering | Direct mutation of financial business fields (amounts, currency, receipts, audit rows) | Ledger integrity | Append-only via DB privileges: no app-role DELETE anywhere, no UPDATE on business columns; corrections only via guarded reversal commands | FIN-INVARIANTS + MIGRATION (privilege assertions) | #4 (privilege base) / #9 | design |
| T-04 | Repudiation | Disputed staff actions on money (allocation, reversal, confirmation) | Audit trust | Audit event on every financial transition **attempt including denials**; sensitive reads logged at service boundary | FIN-INVARIANTS + REDACTION | #4 / #9 | design |
| T-05 | Info disclosure | Cross-workspace access via guessed IDs/URLs (IDOR) | Tenant & owner personal/financial data | Workspace predicate injected in data layer (no unscooped queries); `404` indistinguishable-response convention; attempt audit + rate limit | WS-ISOLATION-IDOR | #4 | design |
| T-06 | Info disclosure | Leakage of private documents (leases, ID documents, condition photos) via storage URLs | Personal data | Private object storage, scoped presigned URLs with expiry (ADR-0008); attachment authorization incl. expired/revoked access (#26 requirements) | AUTHZ-MATRIX extension | #4 storage port / #26 | design |
| T-07 | Info disclosure | Sensitive data in logs, traces, or error messages | Personal data, tokens, money values | Structured logging with redaction rules; REDACTION suite asserts output purity | REDACTION | #4 | design |
| T-08 | Denial of service | Webhook floods and resource enumeration | API availability, ID space | Rate limits + attempt audit (E-12); bounded queues; dead-letter visibility | IDEMPOTENCY + WS-ISOLATION-IDOR | #9 / #11 | design |
| T-09 | Elevation of privilege | Role self-grant or delegation escalation | Admin capabilities | Role changes admin-only + audited; deny-by-default policy engine; matrix probes prove absence of escalation paths | AUTHZ-MATRIX | #4 | design |
| T-10 | Elevation of privilege | AI/automation approving sensitive expenses, resolving disputes, or moving money | Financial integrity | AI holds no approval capabilities — assertion test in the authz layer; disputes and approvals require authorized humans (PRD guardrail) | AUTHZ-MATRIX (negative assertion) | #10/#19 approval flows | design |
| T-11 | Tampering | Secret leakage into code, config, or logs | Credentials | Value-based secret scan gate (G2b) + no-`.env` gate (G2a); rotation runbook and incident recording per CONTRIBUTING rule 5 | quality-gate G2 | active (gate) | tested |
| T-12 | Tampering | Dependency with known vulnerability in backend or frontend | Supply chain | `govulncheck` (Go) + `bun audit` (frontend) in the local gate (G6); no Actions constraint respected — scans run locally | quality-gate G6 | active (gate, activates with code) | tested* |
| T-13 | DoS / Tampering | Database loss or corruption | All records | Backups with RPO ≤ 24 h / RTO ≤ 4 h; restoration drill **required before pilot data exists** — until #31 delivers it, any release introducing persistent customer data is a release blocker | MIGRATION + #31 runbook | #31 | design (blocker tracked) |
| T-14 | Repudiation | Silent "unverified" tax/compliance claims (country rules encoded as fact) | Legal exposure | Tax/compliance behavior requires dated authoritative review before release (#30 gate); fail-closed on unresolved policy keys (e.g., `billing.late_fee_enabled` reserved) | review gate | #30 | design |

\* T-12 gates execute today in docs-only mode (SKIP, loudly reported); they
become enforcing when the code they scan lands.

## Out-of-scope statement

MVP records, allocates, and reconciles payments — it never initiates, custodies,
or settles funds (PRD §3.3). Regulated processing requires a separate
country/regulatory/operational ADR; this register does not cover custody
threats because the capability does not exist (asserted by NO-MONEY-MOVEMENT).
