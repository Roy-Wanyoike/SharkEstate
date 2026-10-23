# SharkEstate — Product Requirements Document (PRD)

| | |
|---|---|
| Document | `docs/PRD.md` |
| Version | 1.0.1-draft |
| Status | In review — requires product-owner, staff-engineer, and QA sign-off (issue #15) |
| Revision | 1.0.1 incorporates independent staff-engineer and QA review round 1 (state-machine completeness, allocation semantics, error contracts, expense domain, currency-scope rule, permission-matrix mechanicalness) |
| Source of truth | GitHub issue #1 (product direction + confirmed decisions), issue #15 |
| Related | #3 (architecture — must align), #14 (quality gates) |
| Requirement IDs | Stable across versions; deprecation is a documented change, never silent removal |

---

## 1. Product vision

SharkEstate helps property agents, landlords, and caretakers manage properties
and tenant relationships with less manual work, while tenants get a clear,
dignified self-service channel.

**The problem, precisely:** property management in African markets still runs
on WhatsApp threads, spreadsheets, and cash-at-the-office. The pain is not
finding tenants; it is operational: knowing who owes what and when, chasing
arrears without losing relationships, proving income and expenses to owners,
coordinating repairs, and never losing a receipt. Records that disagree with
each other destroy trust faster than missing features.

**Success measures (v1 pilot):**

| Measure | Target |
|---|---|
| Time for an agency to onboard a 50-unit portfolio | < 1 day (human benchmark; system AC in FR-POR-05) |
| Monthly rent-invoice generation | Fully automated, zero manual steps |
| Payment-to-reconciled-record time | < 1 hour after confirmation (electronic rails) |
| Owner statement generation | < 5 min p95 for 50 units × 12 months; reproducible from source records |
| Tenant self-service adoption (requests logged in-app vs WhatsApp) | ≥ 60% by month 3 |
| Reported disagreement between dashboard and source records | Zero tolerance — reproducible from authoritative records |

## 2. Target users and personas

Six personas (issue #1). Journey summaries per persona in §4.

| Persona | Core jobs | Pain today |
|---|---|---|
| Agency / property manager | Run portfolios for many landlords: leases, rent, arrears, repairs, reporting | Excel chaos; no single source of truth per landlord |
| Landlord / owner | See performance, rent, arrears, expenses; approve spend | Opaque managers; no evidence trail |
| Caretaker | Inspections, tenant reports, repairs on mobile | Paper notes; no accountability trail |
| Tenant | Check balance, pay, get receipts, raise issues, get notices | No receipts; unclear balances; ignored requests |
| Contractor (supporting) | Receive work orders, submit quotes/progress/completion | Phone-call assignments; no documentation |
| Agency administrator | Workspace settings, membership, permissions, audit | None (no system) |

## 3. MVP boundary

### 3.1 In scope (residential rentals, Africa-first)

- Agency-managed **and** independent landlord workspaces with explicit
  membership, ownership, and isolation (#1 confirmed decision)
- Properties → buildings → units; occupancy and assignments
- Tenant profiles distinct from tenancies/leases; lifecycle and renewals
- Rent schedules → invoices → arrears; **payment recording, allocation, and
  reconciliation** (no money movement — see §3.3)
- Minimal expense records (evidence + approval + reversal) so landlord
  statements reconcile (FR-EXP)
- Maintenance: tenant requests, caretaker inspections, work orders, approvals
- Notifications: in-app first; SMS/email/WhatsApp via consented provider
  adapters where available
- Role-based reporting: portfolio dashboards, landlord statements, arrears,
  occupancy
- Tenant self-service portal (mobile-first, online-first)
- Country profiles: currency precision, timezone, locale, payment-provider
  adapters, per-country policy configuration
- Audit events on sensitive actions; workspace-level isolation, server-enforced

### 3.2 Explicitly out of scope for MVP (do not build without product-owner approval)

- **Money movement:** initiating payments, custody, settlement, payouts,
  merchant-of-record behavior (extension point only — §3.3)
- Commercial-specific lease/workflows (domain must stay extensible; no
  commercial features)
- Offline write/sync queues for caretaker/tenant apps (online-first; deferred
  pending demand validation and a separately reviewed design)
- AI approvals: no AI/automation approves sensitive expenses, resolves payment
  disputes, sets binding rent, or moves money (assistive summaries ok)
- Marketplace/listings, advertising, lead-gen (separate products)
- Deposit-protection schemes, lending, insurance, tenant scoring (regulated —
  require separate country-specific approval)
- Payroll, general HR, accounting packages replacement (exports instead)
- Cross-workspace portfolio rollups (one workspace = one reporting scope; see §9)

### 3.3 Payment model (confirmed decision #1)

MVP **records, allocates, and reconciles** payments that tenants make over
external rails (mobile money, bank, cash). A provider/processing **port**
(domain interface) is defined so future regulated processing can be added per
country via separate regulatory/architecture ADR. **Never** report a payment as
confirmed because a request was submitted or a notification was sent:
confirmation comes only from an authoritative evidence event (e.g., provider
confirmation callback, verified bank statement line, or manager-verified cash
countersigned by evidence). Receipts are issued only after confirmation.

## 4. Role-based journeys (summary; detailed flows in §5 requirement tables)

### 4.1 Agency administrator
1. Creates workspace; invites staff with roles; sets country/currency defaults.
2. Registers properties/buildings/units; assigns staff to property scopes.
3. Configures rent cycles, billables (rent, service charge, water, garbage
   where validated by country profile), and notification templates.
4. Reviews audit log; manages memberships, deactivations, and permission
   changes (all audit-logged).

### 4.2 Agent / property manager
1. Onboards landlords (as workspace clients) and their portfolios.
2. Manages tenants: profiles, tenancies, lease terms, renewals.
3. Watches arrears board; records/allocates payments; issues receipts.
4. Creates work orders from maintenance requests; approves within limits.
5. Generates landlord statements; explains variances from source records.

### 4.3 Landlord / owner
1. Works via agency-managed portfolio (delegated) or independent workspace.
2. Sees occupancy, collections, arrears, expenses for **their** properties only.
3. Approves expenses above threshold; receives monthly statements.
4. Delegates/revokes agency management explicitly (auditable).

### 4.4 Caretaker
1. Mobile-first: sees assigned buildings/units only.
2. Performs inspections with photo evidence; submits structured checklists.
3. Updates work-order progress; marks completion with evidence.
4. Low-bandwidth friendly; visible pending/error states; retry-safe
   submissions (server-authoritative).

### 4.5 Tenant
1. Activates portal access (separate from profile creation; FR-IDW-08).
2. Views current balance, payment history, **confirmed receipts**.
3. Raises maintenance requests with photos; tracks status.
4. Receives notices (rent due, receipts, lease events) on consented channels.

### 4.6 Contractor
1. Receives assigned work orders with scoped info only.
2. Submits quotation, progress updates, completion evidence.
3. Cannot see portfolio-wide data; cannot approve own work.

## 5. Functional requirements

Format: `FR-<DOMAIN>-<NN>` — stable IDs. Each requirement has testable
acceptance criteria (AC). "Server-side" = enforced in backend, never UI-only.
ACs marked `[process]` are review-checklist items (not CI-automatable).

### 5.1 Identity, workspaces, RBAC, audit (FR-IDW)

| ID | Requirement | Acceptance criteria |
|---|---|---|
| FR-IDW-01 | OIDC-based authentication; no local password store in MVP | AC: login via OIDC provider; no password field persisted; session/token lifecycle defined by #3 ADR (traceability: covered-by-#3) |
| FR-IDW-02 | Workspaces: agency-managed and independent landlord; workspace = isolation root | AC: every data read/write is workspace-scoped server-side; cross-workspace access returns `404` (indistinguishable from nonexistent — E-12 convention), denied by default, tested both ways |
| FR-IDW-03 | Membership with roles; role capabilities per §6 matrix | AC: role changes require admin capability and are audit-logged; deactivated members' access is rejected server-side at next request and within 60 s for cached tokens; sessions are not extended |
| FR-IDW-04 | Property-level scoping: staff may be assigned to specific properties | AC: user with scope on property A cannot list/read property B in same workspace (`404`); tested |
| FR-IDW-05 | Ownership vs management: properties have owners and (optionally) managing agents; delegation is explicit, grantable and revocable | AC: landlord sees owned properties regardless of manager; agency access to owner data requires active delegation; revocation effective at next request and within 60 s for cached tokens; all grant/revoke events audited |
| FR-IDW-06 | Sensitive access (owner financials, tenant identity documents, payment records) requires explicit authorization | AC: default-deny for sensitive record sets; granted access is audit-logged with actor, time, record |
| FR-IDW-07 | Audit events: membership/permission changes, approvals, administrative actions, sensitive reads, financial-entity transition attempts | AC: audit entries are append-only (edit/delete attempts rejected with `409`), queryable by workspace admins, include actor, action, entity, timestamp, metadata |
| FR-IDW-08 | Tenant portal activation is separate from tenant profile creation | AC: creating a tenant profile grants no portal access; activation requires the verified-identity step: signed activation link to registered email (if present) **plus** OTP to registered phone; deactivated portal access revokes sessions per FR-IDW-03 timing |

### 5.2 Regional configuration (FR-REG)

| ID | Requirement | Acceptance criteria |
|---|---|---|
| FR-REG-01 | Country profile per workspace: currency, currency precision, timezone, locale formats | AC: all money stored/processed with country precision (no floats); dates/times render in workspace locale and timezone |
| FR-REG-02 | **Currency is fixed per workspace at the first financial record.** Profile currency is locked thereafter (change requires a new workspace or a future migration feature). Currency-safe arithmetic: sums never mix currencies; FX conversions are explicit, recorded events (rate, source, timestamp) | AC: attempted cross-currency sum is rejected; any converted display stores/links its conversion record and is reproducible; workspace with financial records cannot change profile currency (API rejects with `409`) |
| FR-REG-03 | Payment-provider adapters are pluggable per country; MVP ships adapters behind a port interface | AC: adapter selection is workspace configuration; unavailable providers are disabled in UI and API |
| FR-REG-04 | Country-specific policy switches (late-fee legality, notice periods, billable types, escalation schedules) are data, not code — named config keys (e.g., `billing.late_fee_enabled`, `lease.notice_period_days`, `billing.escalation_schedule`) | AC: adding a country does not require schema changes; defaults visible and editable per workspace |
| FR-REG-05 | Pilot country selection is a recorded product-owner decision (see §12/D-1) | AC `[process]`: pilot country recorded in ADR; no country's rules hard-coded in shared code paths |

### 5.3 Portfolio (FR-POR)

| ID | Requirement | Acceptance criteria |
|---|---|---|
| FR-POR-01 | Hierarchy: workspace → properties → buildings → units | AC: unit cannot exist without building (or property when single-building); deletions blocked when records reference entities (soft-delete only for history) |
| FR-POR-02 | Unit registry: type, bedrooms, rent-able state, amenities, media | AC: unit states consistent with occupancy (§7.0); media stored in private storage with scoped access |
| FR-POR-03 | Occupancy status derived from active tenancy, not manually set | AC: unit shows occupied iff an active tenancy exists; manual override impossible; conflicts rejected (`409`) |
| FR-POR-04 | Ownership and management assignments per property; multiple owners supported | AC: owner and manager visible on property; owner changes audit-logged; agents see only managed properties |
| FR-POR-05 | Bulk unit creation for onboarding with reviewable preview and atomic apply | AC: preview shows all resulting units; partial failure rolls back cleanly (no partial unit sets); time-to-onboard is tracked as §1 success measure, not an AC |

### 5.4 Parties, tenancy, leases (FR-LSE)

| ID | Requirement | Acceptance criteria |
|---|---|---|
| FR-LSE-01 | Tenant profiles are persistent persons, distinct from tenancies | AC: moving tenant to new unit/landlord preserves prior tenancy, payment, and maintenance history; profile never overwritten by a new tenancy |
| FR-LSE-02 | Duplicate tenant detection is reviewable, never auto-merge | AC: match predicate — normalized phone equal OR (normalized full-name equal AND shared unit history) — flags likely duplicates with evidence; merge requires human approval; merge is audit-logged with full before/after |
| FR-LSE-03 | Tenancy/lease: unit, tenants (one or more), term dates, rent, **deposit amount (tracked on lease; return handled as task + expense record; no scheme integration in MVP)**, billables, cycle, payment day, notice period | AC: lease dates validated against unit availability; activation rejected if overlapping active tenancy on unit (concurrency-safe: parallel attempts tested — exactly one wins) |
| FR-LSE-04 | Lease lifecycle states per §7.1; renewals create linked successor leases | AC: state transitions enforced server-side; invalid transitions rejected per §7 error contract; renewal preserves history and links predecessor (including backdated renewal from EXPIRED per §7.1) |
| FR-LSE-05 | Lease amendments are versioned (no destructive edits after activation) | AC: post-activation changes create amendment version with audit trail; reports cite the version effective at their period |
| FR-LSE-06 | Tenancy activation requires verified state: unit available, approvals complete (per workspace policy) | AC: activation blocked when unit occupied/under notice; blocked when required approvals missing; every attempt (success/failure) audit-logged |

### 5.5 Rent billing (FR-RNT)

| ID | Requirement | Acceptance criteria |
|---|---|---|
| FR-RNT-01 | Rent schedule generation from lease terms (cycle, day, billables) | AC: schedule previews exactly match issued invoices; generation is idempotent (re-run does not duplicate invoices for a period) |
| FR-RNT-02 | Invoice issuance: per lease per period; line items for each billable; currency per workspace (fixed per FR-REG-02) | AC: invoice totals = Σ line items; mixed currencies impossible; invoice numbers unique, monotonically increasing per workspace; gaps permitted after VOID (no gapless requirement) |
| FR-RNT-03 | Invoice states per §7.2; corrections via void-and-reissue (or credit note where country profile enables) | AC: issued invoices immutable; void requires reason, is audit-logged, requires allocations reversed first (§7.2/§7.4); reissued invoice links to voided one |
| FR-RNT-04 | Arrears computed from issued invoices and **confirmed, non-reversed** payment allocations only. Aging measured in days past due date; buckets (0–30], (31–60], (61+] | AC: balance = Σ invoice totals (non-VOID) − Σ confirmed allocations; partial payments reflected; boundary values 30/31/60/61 days covered by tests; arrears reproducible from records |
| FR-RNT-05 | Reminders/arrears escalation hooks driven by named workspace policy `billing.escalation_schedule` (default: day +3 reminder, day +7 final notice, day +14 escalation flag — data, editable) | AC: reminder generation is idempotent; escalation actions audit-logged; delivery truthfulness per FR-NTF-04 |

### 5.6 Payments (FR-PAY)

| ID | Requirement | Acceptance criteria |
|---|---|---|
| FR-PAY-01 | Record payments from any rail (mobile money, bank, cash) with evidence reference; amount applies against the **lease's outstanding balance** | AC: payment requires method, amount, payer reference, evidence pointer; allocations cannot exceed invoice total; overpayment remainder becomes credit per FR-PAY-08 |
| FR-PAY-02 | Allocation of payments to invoices — **only from CONFIRMED, non-REVERSED payments, to non-VOID invoices** (manual first; suggestions allowed) | AC: allocations sum ≤ payment amount; partial allocation allowed; allocation changes are corrective allocation records (append-only), audit-logged; allocating from PENDING/FAILED/REVERSED payment or to VOID invoice rejected (`409`) |
| FR-PAY-03 | Idempotent imports/callbacks: duplicates collapsed by deterministic key | AC: same provider reference processed twice (including concurrently) yields exactly one payment record; second attempt returns the original result |
| FR-PAY-04 | Confirmation states per §7.3; receipt issuance only on confirmed | AC: pending payment produces no receipt; confirmation requires authoritative evidence event; receipt references payment and allocation-period invoice; receipts are immutable documents whose **visibility** follows payment status (FR-PAY-06) |
| FR-PAY-05 | Reconciliation view: unmatched confirmed payments, invoices with outstanding balance, mismatches | AC: unmatched items listable; resolving match creates audited allocation; dashboard/query equality spot-check reproducible from records |
| FR-PAY-06 | Corrections via reversal entries; no destructive edits/deletes. Reversal effects are deterministic: corrective allocations reverse the original ones; affected invoices recompute (PAID→PARTIALLY_PAID/ISSUED); the issued receipt remains as an immutable historical document, is marked **superseded by reversal** (reversal notice attached), and disappears from the tenant's confirmed-receipts list | AC: reversal references original; net effect reproducible; portal confirmed-receipts list shows only receipts whose payment is CONFIRMED (test: reversal → receipt hidden, balance restored); audit includes reason and actor |
| FR-PAY-07 | No money movement/custody/settlement in MVP | AC: no API initiates transfers; provider port exists but implementations limited to record/reconcile adapters; architecture test asserts absence of payout code paths |
| FR-PAY-08 | Credit: overpayment remainder (confirmed, unallocated amount) is held as credit on the tenant's lease; credit is consumed only by explicit allocation to a future invoice — **never auto-applied** | AC: credit balance = Σ confirmed payments − Σ allocations (per lease); consuming credit creates a normal audited allocation; credit is not a payment-method for money movement |

### 5.7 Maintenance (FR-MNT)

| ID | Requirement | Acceptance criteria |
|---|---|---|
| FR-MNT-01 | Tenant requests (portal) with unit, category, description, photos; fields editable only while OPEN; comments append-only afterwards | AC: tenant sees own requests only; caretaker/agent see requests for scoped units; status per §7.5 |
| FR-MNT-02 | Caretaker inspections (scheduled or ad-hoc) with structured checklists + photo evidence | AC: inspection tied to unit; checklist responses stored; evidence private-stored with scoped access |
| FR-MNT-03 | Work orders: from request or inspection; assignment to staff or contractor; quotation capture | AC: contractor sees assigned orders only; quotes attach to order; below-threshold orders may skip PENDING_APPROVAL per workspace policy `maintenance.approval_threshold` |
| FR-MNT-04 | Approvals: work above `maintenance.approval_threshold` routes to landlord/agency approver | AC: work above threshold cannot move to ASSIGNED without recorded approval; approvals audit-logged; AI/automation never approves (assertion-tested) |
| FR-MNT-05 | Completion requires evidence **and** cost capture; reopened repairs supported (§7.5); costs link to expense records (FR-EXP-01) | AC: completion blocked without evidence + cost; reopen returns to IN_PROGRESS with reason; expense link visible on order |

### 5.8 Expenses (FR-EXP) — minimal MVP scope

| ID | Requirement | Acceptance criteria |
|---|---|---|
| FR-EXP-01 | Record property expenses with amount (workspace currency), category, date, evidence pointer (photo/receipt document), linked property/work order | AC: expense without evidence pointer rejected; totals per property reproducible |
| FR-EXP-02 | Approval workflow per §7.6 with thresholds (policy `expenses.approval_threshold`) | AC: expenses above threshold cannot POST without recorded approval; approvals/requests audit-logged; AI never approves (assertion-tested) |
| FR-EXP-03 | Corrections via reversal entries only (append-only); posted expenses immutable | AC: reversal references original, reason required; landlord statements reconcile: statement expenses = Σ posted non-reversed expenses in period |

### 5.9 Notifications & tasks (FR-NTF)

| ID | Requirement | Acceptance criteria |
|---|---|---|
| FR-NTF-01 | Notification intents decoupled from delivery (intent → channel attempts → status) | AC: intent survives provider outage; delivery attempts recorded; per §7.7 |
| FR-NTF-02 | Channels: in-app (always), SMS/email/WhatsApp via consented adapters | AC: channel without provider config or consent never attempted; opt-out honored across channels |
| FR-NTF-03 | Consent & preferences: per recipient, per channel, per category; suppression checked **at send time** (from QUEUED) | AC: opted-out recipient excluded; consent changes audited with evidence pointer |
| FR-NTF-04 | Truthful status language: "scheduled/sent/failed/exhausted" reflect actual delivery evidence | AC: UI never shows "paid"/"delivered" without confirmation event; failed/exhausted sends visible to staff with manual recovery action |
| FR-NTF-05 | Retry with backoff and cap (`notifications.retry_cap`, default 5 attempts / 24 h); idempotent; duplicates collapsed | AC: retried message produces single recipient-side effect where provider supports idempotency keys; cap → EXHAUSTED (terminal, §7.7); duplicate suppression tested |
| FR-NTF-06 | Task queues for staff (follow-ups, approvals, escalations) with assignment and due dates | AC: tasks scoped to assignee; completion audited; overdue visible in dashboards |

### 5.10 Reporting (FR-RPT)

| ID | Requirement | Acceptance criteria |
|---|---|---|
| FR-RPT-01 | Portfolio dashboards by role (occupancy, collections, arrears, upcoming leases) | AC: manager sees managed portfolio; landlord sees owned properties only; **numbers equal a direct query on the same records** (test: dashboard vs query equality) |
| FR-RPT-02 | Landlord statements: monthly, per property or portfolio; income, expenses (FR-EXP), arrears, occupancy | AC: statement totals reconcile to invoices/payments/allocations/expenses **to the minor unit** (not "cent" — precision is per country profile); PDF export; < 5 min p95 for 50 units × 12 months |
| FR-RPT-03 | Arrears report with aging buckets (FR-RNT-04) and tenant/unit drill-down | AC: drill-down resolves to invoice/payment evidence; filters respect scoping |
| FR-RPT-04 | Occupancy report (current + trend) | AC: derived from tenancy records; historical periods reflect tenancies effective at that time |
| FR-RPT-05 | Export: CSV at minimum; formats documented | AC: exports respect scoping; contain no data user is not authorized for; large portfolios streamed (no unbounded queries — query audit asserts row limits) |
| FR-RPT-06 | Tenant-visible reports are exactly: own current balance, own confirmed receipts, own statements (per `reports.tenant_minimal` policy) | AC: tenant cannot list portfolio reports; matrix cell testable as written |

### 5.11 Tenant self-service (FR-TSP)

| ID | Requirement | Acceptance criteria |
|---|---|---|
| FR-TSP-01 | Mobile-first portal: balance, history, confirmed receipts | AC: critical path per screen < 200 KB; tested at throttled profile 250 kbps / 500 ms RTT on Android Go-class device; receipts downloadable; only receipts whose payment is CONFIRMED are listed (FR-PAY-06) |
| FR-TSP-02 | Raise + track maintenance requests with photos; edit only while OPEN; comments append-only | AC: status transitions visible to tenant; tenant sees own unit's requests only |
| FR-TSP-03 | Notices received per consented channels; lease documents accessible | AC: documents private-stored, tenant-scoped; access audit-logged |
| FR-TSP-04 | Payment instructions per workspace configuration (no in-app money movement in MVP) | AC: instructions reflect workspace's rails; "Pay" affordances link out or instruct; never represent payment as completed without confirmation |

## 6. Permission matrix

Roles: **Agency Admin (AA)**, **Agent/Property Manager (PM)**, **Landlord/Owner (LO)**, **Caretaker (CT)**, **Tenant (TN)**, **Contractor (CN)**.
Scope legend: **W** = workspace, **P** = property-scoped assignments, **O** = own records only, **A** = assigned records only.
Capabilities are atomic: **R**ead, **C**reate, **U**pdate, **D**elete(soft), plus domain verbs (`issue`, `record`, `confirm`, `reverse`, `allocate`, `approve`). Cell format: `capability (scope)`. **Deny by default**: any action not listed is denied and cross-workspace denies return `404`.

| Resource / action | AA | PM | LO | CT | TN | CN |
|---|---|---|---|---|---|---|
| Workspace settings & country profile | RCU (W) | R (W) | — | — | — | — |
| Memberships, roles, invitations | RCU (W) | — | — | — | — | — |
| Audit log | R (W) | R (P)¹ | R (O) | — | — | — |
| Properties / buildings / units | RCUD (W) | RCUD (P) | R (O) | R (A) | R (O unit) | — |
| Owners & delegation grants | RCU (W) | R (P) | RCU (O) | — | — | — |
| Tenant profiles | RCU (W) | RCU (P) | R (O) | R-contact (A)² | R (O) | — |
| Tenant identity documents | R (W) | R (P)² | R (O) | — (unless `pm.identity_doc_access` grants CT) | R (O) | — |
| Tenancies / leases | RCU (W) | RCU (P) + activate/terminate/renew (P) | R (O) | R (A) | R (O) | — |
| Rent schedules & invoices | RCU (W) + issue (W) | RCU (P) + issue (P) | R (O) | — | R (O) | — |
| Payment records | R (W) + record/confirm/reverse (W) | R (P) + record/confirm (P)³ | R (O) | — | R (O) | — |
| Allocations | RC (W) | RC (P) | R (O) | — | R (O) | — |
| Receipts | issue (W) / R (W) | issue (P) / R (P) | R (O) | — | R (O) | — |
| Maintenance requests | RCUD (W) | RCUD (P) | R (O) | RU (A) | RC (O) + U while OPEN (O) | R (A) |
| Inspections | RCU (W) | RCU (P) | R (O) | RC (A) | R (O unit) | — |
| Work orders | RCU (W) + approve (W) | RCU (P) + approve (P, ≤ threshold) | approve (O, > `maintenance.approval_threshold`) | RU (A) | R (O) | RU (A) |
| Expenses | RCUD (W) + approve (W) | RC (P) + approve (P, ≤ threshold) | approve (O, > `expenses.approval_threshold`) | — | — | — |
| Reports / statements | R (W) | R (P) | R (O) | — | R (O)⁴ (FR-RPT-06 set) | — |
| Own notification preferences | RU (O) | RU (O) | RU (O) | RU (O) | RU (O) | RU (O) |

¹ PM sees audit for scoped properties; admin-only categories require `audit.admin_categories` policy.
² Default: PM/CT do **not** see raw identity documents; grantable via named policies (`pm.identity_doc_access`, `ct.identity_doc_access`). Contact info visible to CT for assigned units.
³ `confirm` and `reverse` are AA/PM capabilities only; self-confirmation of a cash payment recorded by the same actor requires a second-person verification per policy `payments.second_person_verification` (default on for cash) — recorded as audit evidence.
⁴ Enumerated: own balance, own confirmed receipts, own statements (FR-RPT-06). No portfolio reports.

**Defaults:** deny by default; every allow above is explicit in authorization
policy and tested both ways (permitted **and** denied). Matrix is converted
mechanically into the AUTHZ-MATRIX test suite (see #14).

## 7. State-transition tables (authoritative)

**Global error contract (applies to every machine in §7):** a transition not
listed, or whose guard fails, is rejected with HTTP `409` / domain error
`TRANSITION_INVALID` (or the specific guard code, e.g. `UNIT_OCCUPIED`); the
entity's state is unchanged; the attempt is audit-logged when the entity is
financial or the action is sensitive (FR-IDW-07). No direct status writes from
API/UI — transitions happen only through domain commands.

### 7.0 Unit

VACANT → OCCUPIED (tenancy activation) → NOTICE (active tenancy enters notice period) → VACANT (tenancy ends).
OCCUPIED/NOTICE → MAINTENANCE is **forbidden** (maintenance runs against occupied units; only VACANT units may be marked MAINTENANCE, manually, returning to VACANT). Occupancy is derived (FR-POR-03).

### 7.1 Tenancy / Lease

States: DRAFT, ACTIVE, EXPIRING, EXPIRED, RENEWED, TERMINATED, CANCELLED.
`EXPIRING` is a real state entered automatically when `endDate − today ≤ lease.expiring_window_days` (default 60, workspace config).

| From | Event | To | Guards | Side effects |
|---|---|---|---|---|
| — | Create draft | DRAFT | unit exists; dates valid | — |
| DRAFT | Activate | ACTIVE | unit VACANT; approvals complete; no overlap (concurrency-safe: parallel activations → exactly one wins, loser gets `UNIT_OCCUPIED`) | unit→OCCUPIED; schedule generated; audit |
| DRAFT | Cancel | CANCELLED | — | terminal; audit with reason |
| ACTIVE | endDate − today ≤ window (cron) | EXPIRING | — | renewal reminders (FR-NTF) |
| ACTIVE/EXPIRING | Renew (new successor lease) | RENEWED (successor → ACTIVE) | successor lease valid; no overlap | link predecessor; continuity of schedule; audit |
| ACTIVE/EXPIRING | Terminate (agreed) | TERMINATED | notice period honored per country profile (`lease.notice_period_days`) | unit→VACANT on effective end date; deposit return task created |
| EXPIRED | Renew (backdated) | RENEWED (successor ACTIVE) | successor dates consistent | link; audit |
| EXPIRED | Holdover resolution (manual) | TERMINATED | reason "holdover" recorded | unit→VACANT; flagged late-termination in audit |

Rules: states change only via domain commands; transitions audited. EXPIRED arises from cron when endDate passes without renewal/termination.

### 7.2 Invoice

States: DRAFT, ISSUED, PARTIALLY_PAID, PAID, VOID. `overdue` is a **derived flag** (due date passed while ISSUED/PARTIALLY_PAID) — not a state — so partial payment and overdue coexist (aging per FR-RNT-04).

| From | Event | To | Guards |
|---|---|---|---|
| — | Generate (schedule) | DRAFT | idempotent per lease+period |
| DRAFT | Issue | ISSUED | totals = Σ items; currency = workspace currency |
| DRAFT | Discard | VOID | reason; audit |
| ISSUED | Allocate partial (confirmed payment) | PARTIALLY_PAID | allocation < total |
| ISSUED | Allocate full (confirmed payments) | PAID | Σ allocations = total |
| PARTIALLY_PAID | Allocate remainder (confirmed payments) | PAID | Σ allocations = total |
| ISSUED/PARTIALLY_PAID/PAID | Void | VOID | reason; **all allocations reversed first** (§7.4); audit; reissue links to voided |
| any ← recompute | Allocation added/reversed | (per Σ confirmed allocations vs total) | state always consistent with allocations (PAID ⇔ Σ = total; PARTIALLY_PAID ⇔ 0 < Σ < total; ISSUED ⇔ Σ = 0) |

Allocations to VOID invoices are rejected (`409 INVOICE_VOID`). VOID is terminal.

### 7.3 Payment

States: PENDING, CONFIRMED, FAILED, REVERSED.

| From | Event | To | Guards |
|---|---|---|---|
| — | Record (rail evidence) | PENDING | amount, method, payer ref, evidence pointer |
| PENDING | Authoritative confirmation event | CONFIRMED | provider callback / verified statement line / verified cash + evidence |
| PENDING | Provider failure evidence | FAILED | reason recorded |
| FAILED | Manual re-confirmation (staff) | CONFIRMED | **only** via verified statement evidence + audit (never from callback replay); handles late statement lines after timeout |
| CONFIRMED | Correction | REVERSED | reversal entry; corrective allocations reverse originals; invoices recompute (§7.2); receipt superseded (FR-PAY-06); reason; audit |

Allocatable: CONFIRMED only. REVERSED and FAILED are non-allocatable. REVERSED is terminal (a re-correction is a new confirmed payment + new reversal evidence chain, audited).

### 7.4 Allocation / Receipt

| Entity | States/lifecycle | Rules |
|---|---|---|
| Allocation | exists → corrected-by-successor (append-only) | created against (CONFIRMED payment, non-VOID invoice); corrective allocation supersedes, never edits; Σ allocations per payment ≤ payment amount; Σ per invoice ≤ invoice total |
| Receipt | ISSUED → SUPERSEDED (payment reversed) | immutable document; generated from confirmed payment; SUPERSEDED keeps document with reversal notice attached; hidden from tenant confirmed-receipts list (FR-PAY-06); regeneration of the *view* (PDF) is allowed, re-issuance of a new receipt number is impossible |

### 7.5 Maintenance request / Work order

Request: OPEN → ACKNOWLEDGED → IN_PROGRESS → RESOLVED → CLOSED.
Reopen: RESOLVED→IN_PROGRESS **and** CLOSED→IN_PROGRESS (reason required, audit-logged — E-09). Edits to fields only while OPEN; comments append-only afterwards.

Work order: DRAFT → PENDING_APPROVAL (only if cost > `maintenance.approval_threshold`) → APPROVED → ASSIGNED → IN_PROGRESS → COMPLETED → CLOSED.
Guards: COMPLETED requires completion evidence + cost captured (FR-MNT-05); CLOSED by approver/admin only. REJECTED (from PENDING_APPROVAL, reason) → back to DRAFT for revise/resubmit. Reopen: CLOSED→IN_PROGRESS with reason; relink to a new request allowed (audit).

### 7.6 Expense

DRAFT → SUBMITTED → APPROVED (≤ threshold auto-approves per policy) → POSTED; REJECTED (from SUBMITTED, reason) → back to DRAFT. POSTED → REVERSED (correction; reason; audit). POSTED expenses immutable. Approvals above threshold require LO/AA per matrix.

### 7.7 Notification delivery

INTENT_CREATED → QUEUED(channel) → { SUPPRESSED (consent/opt-out checked at send) | SENT (provider ack) }.
SENT → DELIVERED (where evidence exists) | FAILED (provider failure).
FAILED → QUEUED (retry with backoff, while attempts < `notifications.retry_cap`) or EXHAUSTED (cap reached — terminal, visible to staff, manual recovery action).
One intent, many channel attempts; attempts append-only; duplicates collapsed (FR-NTF-05).

## 8. Acceptance examples & edge cases (must be test cases)

| # | Scenario | Expected behavior |
|---|---|---|
| E-01 | Partial payment on invoice (record → confirm → allocate part) | Invoice ISSUED→PARTIALLY_PAID after allocation; balance reduces; arrears reflects remainder; receipt only after confirmation; **no state change while payment PENDING** |
| E-02 | Duplicate provider callback (same reference, twice, concurrent) | One payment record; second attempt returns original result (idempotency key) |
| E-03 | Unmatched confirmed payment (no obvious invoice) | Appears in reconciliation unmatched list; staff resolves with audited allocation |
| E-04 | Late rent with default `billing.escalation_schedule` (+3 reminder, +7 final notice, +14 flag) | Correct action per day offset; every automated action audit-logged; no auto-penalty unless `billing.late_fee_enabled` |
| E-05 | Two managers concurrently activate leases on the same unit | Exactly one activation succeeds; loser receives `409 UNIT_OCCUPIED`; unit state consistent |
| E-06 | Lease renewal at/near end date | Successor lease linked to predecessor; history preserved; unit stays OCCUPIED; schedule continuity |
| E-07 | Disputed payment (tenant claims paid, no evidence) | Payment stays PENDING; appears in unmatched list; staff may append an **audited dispute note** (append-only field on payment record); no receipt; never auto-resolves |
| E-08 | Failed SMS at arrears day +3 | Intent survives; attempt FAILED visible; retry with backoff per §7.7; suppression re-checked at send |
| E-09 | Reopened repair after CLOSED | Request CLOSED→IN_PROGRESS with reason (§7.5); work order relinked or new order created; history intact |
| E-10 | Revoked agency access to owner portfolio | Access denied at next request and within 60 s for cached tokens; pre-revocation sensitive reads were audit-logged; landlord notification task created per `access.revocation_notify` policy |
| E-11 | Mixed-currency portfolio query | Cross-currency sums rejected with explicit error; reports show **per-currency breakdown**; FX conversion only as explicit action citing a recorded conversion (rate, source, timestamp) |
| E-12 | Workspace A user guesses workspace B resource URLs/IDs | Response is `404` (indistinguishable from nonexistent — convention), attempt audit-logged (rate-limited) |
| E-13 | Overpayment (credit) | Allocation caps at invoice total; remainder held as lease credit (FR-PAY-08); consumed only by explicit later allocation; never auto-applied |
| E-14 | Receipt issued, payment later reversed | Receipt becomes SUPERSEDED with reversal notice; hidden from tenant confirmed-receipts list; invoice recomputes; balance restored; full audit chain |

## 9. Africa-first regional model

**Platform-wide (code):** workspace model, RBAC, audit, financial records,
state machines, notification intents, adapter ports, i18n framework,
accessibility standards.

**Country profile (data/config):** currency + precision (e.g., KES 2dp; XOF 0dp —
hence "minor unit", never "cent", in all money ACs), timezone, date/number
formats, language(s) (English/Kiswahili where approved), billable types legality
(e.g., late fees), notice-period defaults, escalation schedule defaults,
payment-provider adapters and their capabilities, tax-export surface (post-#30
verification only).

**Currency-scope rule (FR-REG-02):** workspace currency is fixed at the first
financial record; landlord statements and all reports are **per workspace**;
cross-workspace rollups are out of scope for MVP (§3.2). Historical
mixed-currency reporting is thereby impossible by construction; E-11 guards the
invariant and any future multi-currency feature requires a new ADR.

**Pilot country:** recommendation recorded in §11 as a decision requiring
product-owner sign-off; no country's rules hard-coded in shared code paths
(FR-REG-05).

## 10. Non-functional requirements

Test environment baseline for performance ACs: dataset = 50 units, 12 months of
history (~600 invoices, ~1,800 payment records, ~200 maintenance records);
numbers are **p95** unless stated.

| Area | Requirement |
|---|---|
| Accessibility | WCAG 2.1 AA for portal surfaces; keyboard-complete; screen-reader labels; axe audit in local gate (#14/#28) |
| Low bandwidth / mobile | Tenant/caretaker critical paths < 200 KB per screen; tested at 250 kbps / 500 ms RTT (2G profile), Android Go-class device; visible pending/error states; retry-safe submissions |
| Privacy & data protection | Data minimization; private object storage with scoped, expiring access; no sensitive data in logs/traces/errors (automated redaction tests); retention policy per workspace config (`retention.<category>_days`); tenant exports consent-scoped (later #23) |
| Auditability | Append-only audit of sensitive actions and financial transition attempts; financial records immutable with corrections via reversals; reports reproducible (dashboard/query equality tests) |
| Security | Server-side authorization everywhere; deny by default with `404` cross-workspace convention; OIDC sessions; token revocation propagation ≤ 60 s; secrets never in code; dependency & secret scanning in local gate (#14) |
| Performance | Dashboards < 3 s p95 (dataset above); statement < 5 min p95; invoice generation run for 50 leases < 60 s; no unbounded queries (row-limit audit); pagination/streaming everywhere |
| Reliability | Idempotent scheduled jobs (run-twice test); retry-safe webhooks (E-02); crash-safe imports (kill-mid-import test); backups/restoration per #31 |
| Support & operations | Health checks; structured logging with redaction; incident runbook (#31); any displayed number traceable to source records (reproducibility suite) |

## 11. Assumptions, unresolved questions, risks

**Decisions requiring product-owner sign-off (blockers where marked):**

| # | Decision | Recommendation | Status |
|---|---|---|---|
| D-1 | **Pilot country** | Kenya (evidence: founding context, Nairobi sibling project, mobile-money ubiquity) | 🔴 BLOCKS #3 final approval & #5 implementation detail |
| D-2 | Identity provider hosting | Keycloak, self-hosted in staging/prod; sandbox uses compose | ⏳ ADR in #3 |
| D-3 | Payment provider for pilot sandbox (record/reconcile adapter) | M-Pesa Daraja sandbox | ⏳ credentials required before #9 |
| D-4 | Kiswahili scope for MVP UI | Core tenant/caretaker surfaces only | ⏳ #28 |
| D-5 | Late-fee/penalty policy default | Off by default; per-country enablement (`billing.late_fee_enabled`) | ⏳ country profile data after D-1 |

**Open questions (tracked, not silently assumed):**
- FX rate source/trust for explicit conversions (MVP: manual rate + source URL recorded; no automatic FX)
- Tenant identity-verification UX depth for FR-IDW-08 (link + OTP chosen; adjust after pilot feedback)
- Holdover policy defaults (E: manual termination with "holdover" flag — revisit with pilot agencies)
- Retention day-values per category (need legal input per country; config keys exist from day one)

**Assumptions (explicitly not facts):** tenants have smartphones for portal
(fallback: notices by SMS); agencies have ≥1 smartphone for caretakers;
electronic rails dominate rent payments; landlords trust agency-held records
if evidence-backed.

**Risks:** provider callback reliability (mitigate: idempotency + reconciliation
loops + manual re-confirmation path §7.3); low digital literacy among caretakers
(mitigate: checklists, photos, minimal typing); multi-country complexity creep
(mitigate: profile-only variation, per §9); scope expansion into regulated
payments (mitigate: §3.3 hard boundary + FR-PAY-07 architecture test).

## 12. Review & sign-off record

| Role | Name/Handle | Verdict | Date |
|---|---|---|---|
| Product owner | @Roy-Wanyoike | ⏳ pending | — |
| Staff engineer (independent) | PR #36 review thread | round 1: REQUEST_CHANGES (F-1..F-5) → addressed in v1.0.1 | 2026-10-23 |
| QA representative | PR #36 review thread | round 1: REQUEST_CHANGES (7 blocking) → addressed in v1.0.1 | 2026-10-23 |

Round-2 re-review of v1.0.1 pending. Sign-off issue comments supersede this
table once recorded.
