# SharkEstate — Product Requirements Document (PRD)

| | |
|---|---|
| Document | `docs/PRD.md` |
| Version | 1.0.0-draft |
| Status | In review — requires product-owner, staff-engineer, and QA sign-off (issue #15) |
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
| Time for an agency to onboard a 50-unit portfolio | < 1 day |
| Monthly rent-invoice generation | Fully automated, zero manual steps |
| Payment-to-reconciled-record time | < 1 hour after confirmation (electronic rails) |
| Owner statement generation | < 5 minutes, reproducible from source records |
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
| Contractor | Receive work orders, submit quotes/progress/completion | Phone-call assignments; no documentation |
| Agency administrator | Workspace settings, membership, permissions, audit | None (no system) |

## 3. MVP boundary

### 3.1 In scope (residential rentals, Africa-first)

- Agency-managed **and** independent landlord workspaces with explicit
  membership, ownership, and isolation (#1 confirmed decision)
- Properties → buildings → units; occupancy and assignments
- Tenant profiles distinct from tenancies/leases; lifecycle and renewals
- Rent schedules → invoices → arrears; **payment recording, allocation, and
  reconciliation** (no money movement — see §3.3)
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
1. Activates portal access (separate from profile creation; §5 FR-IDW).
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

### 5.1 Identity, workspaces, RBAC, audit (FR-IDW)

| ID | Requirement | Acceptance criteria |
|---|---|---|
| FR-IDW-01 | OIDC-based authentication; no local password store in MVP | AC: login via OIDC provider; no password field persisted; session lifecycle per architecture (#3) |
| FR-IDW-02 | Workspaces: agency-managed and independent landlord; workspace = isolation root | AC: every data read/write is workspace-scoped server-side; cross-workspace access denied by default and tested (both allowed and denied paths) |
| FR-IDW-03 | Membership with roles; role capabilities per §6 matrix | AC: role changes require admin capability and are audit-logged; deactivated members lose access immediately |
| FR-IDW-04 | Property-level scoping: staff may be assigned to specific properties | AC: user with scope on property A cannot list/read property B in same workspace; tested |
| FR-IDW-05 | Ownership vs management: properties have owners and (optionally) managing agents; delegation is explicit, grantable and revocable | AC: landlord can see properties owned regardless of manager; agency access to owner data requires active delegation; revocation takes effect ≤ 1 session; all grant/revoke events audited |
| FR-IDW-06 | Sensitive access (owner financials, tenant identity documents, payment records) requires explicit authorization | AC: first access to a sensitive record set by a role not holding it is denied; granted access is audit-logged with actor, time, record |
| FR-IDW-07 | Audit events: membership/permission changes, approvals, administrative actions, sensitive reads | AC: audit entries are append-only, queryable by workspace admins, include actor, action, entity, timestamp, metadata; audit cannot be edited/deleted via any API |
| FR-IDW-08 | Tenant portal activation is separate from tenant profile creation | AC: creating a tenant profile grants no portal access; activation requires verified tenant identity step; deactivated portal access revokes sessions |

### 5.2 Regional configuration (FR-REG)

| ID | Requirement | Acceptance criteria |
|---|---|---|
| FR-REG-01 | Country profile per workspace: currency, currency precision, timezone, locale formats | AC: all money stored/processed with country precision (no floats); dates/times render in workspace locale and timezone; changing profile affects only future records |
| FR-REG-02 | Currency-safe arithmetic: sums never mix currencies; FX conversions are recorded events (rate, source, timestamp) | AC: attempted cross-currency sum is rejected; converted reports store the conversion record and are reproducible |
| FR-REG-03 | Payment-provider adapters are pluggable per country; MVP ships adapters behind a port interface | AC: adapter selection is workspace configuration; unavailable providers are disabled in UI and API |
| FR-REG-04 | Country-specific policy switches (e.g., late-fee legality, notice periods, billable types) are data, not code | AC: adding a country does not require schema changes; defaults visible and editable per workspace |
| FR-REG-05 | Pilot country selection is a recorded product-owner decision (see §12) | AC: pilot country recorded in ADR; no country's rules hard-coded in shared code paths |

### 5.3 Portfolio (FR-POR)

| ID | Requirement | Acceptance criteria |
|---|---|---|
| FR-POR-01 | Hierarchy: workspace → properties → buildings → units | AC: unit cannot exist without building (or property when single-building); deletions blocked when records reference entities (soft-delete only for history) |
| FR-POR-02 | Unit registry: type, bedrooms, rent-able state, amenities, media | AC: unit states consistent with occupancy (§7); media stored in private storage with scoped access |
| FR-POR-03 | Occupancy status derived from active tenancy, not manually set | AC: unit shows occupied iff an active tenancy exists; manual override impossible; conflicts rejected |
| FR-POR-04 | Ownership and management assignments per property; multiple owners supported | AC: owner and manager visible on property; owner changes audit-logged; agents see only managed properties |
| FR-POR-05 | Bulk unit creation for onboarding (e.g., N units, prefix, types) | AC: bulk create produces reviewable preview; partial failure rolls back cleanly; 50-unit onboarding < 1 day incl. leases entry |

### 5.4 Parties, tenancy, leases (FR-LSE)

| ID | Requirement | Acceptance criteria |
|---|---|---|
| FR-LSE-01 | Tenant profiles are persistent persons, distinct from tenancies | AC: moving tenant to new unit/landlord preserves prior tenancy, payment, and maintenance history; profile never overwritten by a new tenancy |
| FR-LSE-02 | Duplicate tenant detection is reviewable, never auto-merge | AC: likely duplicates flagged with evidence; merge requires human approval and is audit-logged with full before/after |
| FR-LSE-03 | Tenancy/lease: unit, tenants (one or more), term dates, rent, deposit, billables, cycle, payment day, notice period | AC: lease dates validated against unit availability; activation rejected if overlapping active tenancy on unit (concurrency-safe: tested with parallel attempts) |
| FR-LSE-04 | Lease lifecycle states per §7.1; renewals create linked successor leases | AC: state transitions enforced server-side; invalid transitions rejected; renewal preserves history and links predecessor |
| FR-LSE-05 | Lease amendments are versioned (no destructive edits after activation) | AC: post-activation changes create amendment version with audit trail; reports cite the version effective at their period |
| FR-LSE-06 | Tenancy activation requires verified state: unit available, approvals complete (per workspace policy) | AC: activation blocked when unit occupied/under notice; blocked when required approvals missing; every attempt (success/failure) audit-logged |

### 5.5 Rent billing (FR-RNT)

| ID | Requirement | Acceptance criteria |
|---|---|---|
| FR-RNT-01 | Rent schedule generation from lease terms (cycle, day, billables) | AC: schedule previews exactly match issued invoices; generation is idempotent (re-run does not duplicate invoices for a period) |
| FR-RNT-02 | Invoice issuance: per lease per period; line items for each billable; currency per workspace | AC: invoice totals = Σ line items; mixed currencies impossible; invoice numbers unique, sequential per workspace |
| FR-RNT-03 | Invoice states per §7.2; corrections via void-and-reissue (or credit note where country profile enables) | AC: issued invoices immutable; void requires reason, is audit-logged; reissued invoice links to voided one |
| FR-RNT-04 | Arrears computed from issued invoices and confirmed payments only | AC: balance = Σ invoices − Σ allocated confirmed payments; partial payments reflected; arrears aging (1–30/31–60/60+ days) reproducible from records |
| FR-RNT-05 | Reminders/arrears escalation hooks per workspace policy | AC: reminder generation is idempotent; escalation actions audit-logged; delivery truthfulness per FR-NTF-04 |

### 5.6 Payments (FR-PAY)

| ID | Requirement | Acceptance criteria |
|---|---|---|
| FR-PAY-01 | Record payments from any rail (mobile money, bank, cash) with evidence reference | AC: payment requires method, amount, payer reference, evidence pointer; cannot exceed outstanding balance unless policy allows advance (recorded as credit) |
| FR-PAY-02 | Allocation of payments to invoices (manual first; suggestions allowed) | AC: allocations sum ≤ payment amount; partial allocation allowed; allocation changes are new allocation records (append-only), audit-logged |
| FR-PAY-03 | Idempotent imports/callbacks: duplicates collapsed by deterministic key | AC: same provider reference processed twice yields one payment record; concurrent duplicate submissions tested |
| FR-PAY-04 | Confirmation states per §7.3; receipt issuance only on confirmed | AC: pending payment produces no receipt; confirmation requires authoritative evidence event; receipt references payment and invoice; receipt re-issue impossible |
| FR-PAY-05 | Reconciliation view: unmatched payments, unmatched invoices, mismatches | AC: unmatched items listable; resolving matching creates audited allocation; reports never disagree with source records (spot-check reproducible) |
| FR-PAY-06 | Corrections via reversal entries; no destructive edits/deletes | AC: reversal references original; net effect reproducible; audit includes reason and actor |
| FR-PAY-07 | No money movement/custody/settlement in MVP | AC: no API initiates transfers; provider port exists but implementations limited to record/reconcile adapters; architecture test asserts absence of payout code paths |

### 5.7 Maintenance (FR-MNT)

| ID | Requirement | Acceptance criteria |
|---|---|---|
| FR-MNT-01 | Tenant requests (portal) with unit, category, description, photos | AC: tenant sees own requests only; caretaker/agent see requests for scoped units; status per §7.4 |
| FR-MNT-02 | Caretaker inspections (scheduled or ad-hoc) with structured checklists + photo evidence | AC: inspection tied to unit; checklist responses stored; evidence private-stored with scoped access |
| FR-MNT-03 | Work orders: from request or inspection; assignment to staff or contractor; quotation capture | AC: contractor sees assigned orders only; quotes attach to order; approval before work per policy thresholds |
| FR-MNT-04 | Approvals: expense thresholds route to landlord/agency approver | AC: work above threshold cannot start without recorded approval; approvals audit-logged; AI/automation never approves (assertion-tested) |
| FR-MNT-05 | Completion evidence + cost capture; reopened repairs supported | AC: completion requires evidence; reopen returns to in-progress with reason; costs link to expense records (FR-EXP domain later; interim: cost field on order) |

### 5.8 Notifications & tasks (FR-NTF)

| ID | Requirement | Acceptance criteria |
|---|---|---|
| FR-NTF-01 | Notification intents decoupled from delivery (intent → channel attempts → status) | AC: intent survives provider outage; delivery attempts recorded; per §7.6 |
| FR-NTF-02 | Channels: in-app (always), SMS/email/WhatsApp via consented adapters | AC: channel without provider config or consent never attempted; opt-out honored across channels |
| FR-NTF-03 | Consent & preferences: per recipient, per channel, per category; suppression list | AC: opted-out recipient excluded; consent changes audited with evidence pointer; suppression checked at send time |
| FR-NTF-04 | Truthful status language: "scheduled/sent/failed/confirmed" reflect actual delivery evidence | AC: UI never shows "paid"/"delivered" without confirmation event; failed sends visible to staff with retry action |
| FR-NTF-05 | Retry with backoff, idempotent; duplicates collapsed | AC: retried message produces single recipient-side effect where provider supports idempotency keys; duplicate suppression tested |
| FR-NTF-06 | Task queues for staff (follow-ups, approvals, escalations) with assignment and due dates | AC: tasks scoped to assignee; completion audited; overdue visible in dashboards |

### 5.9 Reporting (FR-RPT)

| ID | Requirement | Acceptance criteria |
|---|---|---|
| FR-RPT-01 | Portfolio dashboards by role (occupancy, collections, arrears, upcoming leases) | AC: manager sees managed portfolio; landlord sees owned properties only; numbers reproducible from source records (test: compare dashboard vs query on same records) |
| FR-RPT-02 | Landlord statements: monthly, per property or portfolio; income, expenses, arrears, occupancy | AC: statement generation < 5 min for 50 units; statement totals reconcile to invoices/payments/allocation records to the cent; PDF export |
| FR-RPT-03 | Arrears report with aging buckets and tenant/unit drill-down | AC: drill-down resolves to invoice/payment evidence; filters respect scoping |
| FR-RPT-04 | Occupancy report (current + trend) | AC: derived from tenancy records; historical periods reflect tenancies effective at that time |
| FR-RPT-05 | Export: CSV at minimum; formats documented | AC: exports respect scoping; contain no data user is not authorized for; large portfolios paginated/streamed (no unbounded queries) |

### 5.10 Tenant self-service (FR-TSP)

| ID | Requirement | Acceptance criteria |
|---|---|---|
| FR-TSP-01 | Mobile-first portal: balance, history, confirmed receipts | AC: usable on low-end Android at 2G-class bandwidth; receipts downloadable; only confirmed receipts visible |
| FR-TSP-02 | Raise + track maintenance requests with photos | AC: status transitions visible to tenant; tenant sees own unit's requests only |
| FR-TSP-03 | Notices received per consented channels; lease documents accessible | AC: documents private-stored, tenant-scoped; access audit-logged |
| FR-TSP-04 | Payment instructions per workspace configuration (no in-app money movement in MVP) | AC: instructions reflect workspace's rails; "Pay" affordances link out or instruct; never represent payment as completed without confirmation |

## 6. Permission matrix

Roles: **Agency Admin (AA)**, **Agent/Property Manager (PM)**, **Landlord/Owner (LO)**, **Caretaker (CT)**, **Tenant (TN)**, **Contractor (CN)**.
Scope legend: **W** = workspace, **P** = property-scoped assignments, **O** = own records only, **A** = assigned records only.

| Resource / action | AA | PM | LO | CT | TN | CN |
|---|---|---|---|---|---|---|
| Workspace settings & country profile | RW (W) | R (W) | — | — | — | — |
| Memberships, roles, invitations | RW (W) | — | — | — | — | — |
| Audit log (sensitive events) | R (W) | R (P)¹ | R (O) | — | — | — |
| Properties / buildings / units | RW (W) | RW (P) | R (O) | R (A) | R (O unit) | — |
| Owners & delegation grants | RW (W) | R (P) | RW (O) | — | — | — |
| Tenant profiles (identity docs) | RW (W) | RW (P)² | R (O)² | R (A)² | R (O) | — |
| Tenancies / leases | RW (W) | RW (P) | R (O) | R (A) | R (O) | — |
| Rent schedules & invoices | RW (W) | RW (P) | R (O) | — | R (O) | — |
| Payment records & allocations | RW (W) | RW (P) | R (O) | — | R (O) | — |
| Receipts (issue) | ✓ (W) | ✓ (P) | — | — | R (O) | — |
| Maintenance requests | RW (W) | RW (P) | R (O) | RW (A) | RW (O) | R (A) |
| Work orders & approvals | RW (W) | RW (P) | Approve (O, above threshold) | Update (A) | R (O) | Update (A) |
| Expenses & approvals | RW (W) | RW (P) | Approve (O) | — | — | — |
| Reports / statements | R (W) | R (P) | R (O) | — | R (O) minimal | — |
| Notification preferences (own) | RW (O) | RW (O) | RW (O) | RW (O) | RW (O) | RW (O) |

¹ Admin-only categories visible to PM only where policy enables; sensitive reads audit-logged (FR-IDW-06/07).
² Identity documents readable only to roles granted sensitive access; default PM excludes raw ID images.

**Defaults:** deny by default; every allow above is explicit in authorization
policy and tested both ways (permitted **and** denied).

## 7. State-transition tables (authoritative)

### 7.1 Tenancy / Lease

| From | Event | To | Guards | Side effects |
|---|---|---|---|---|
| — | Create draft | DRAFT | unit exists; dates valid | — |
| DRAFT | Activate | ACTIVE | unit not occupied/under notice; approvals complete; no overlap (concurrency-safe) | unit→occupied; schedule generated; audit |
| ACTIVE | End-date reached (cron) | EXPIRING→EXPIRED | — | renewal reminders (FR-NTF) |
| ACTIVE | Renew | RENEWED (successor lease ACTIVE) | no overlap | link predecessor; audit |
| ACTIVE | Terminate (agreed) | TERMINATED | notice period honored per country profile | unit→vacant on end date; deposit task created |
| EXPIRED | — | terminal | — | unit→vacant |

Rules: states change only via domain commands; transitions audited; no direct
status writes from API/UI.

### 7.2 Invoice

| From | Event | To | Guards |
|---|---|---|---|
| — | Generate (schedule) | DRAFT | idempotent per lease+period |
| DRAFT | Issue | ISSUED | totals = Σ items; currency set |
| ISSUED | Allocate partial payment | PARTIALLY_PAID | allocation ≤ balance |
| ISSUED/PARTIALLY_PAID | Due date passes unpaid | OVERDUE | arrears computed |
| ISSUED/PARTIALLY_PAID/OVERDUE | Payments cover total | PAID | Σ allocations = total |
| ISSUED/OVERDUE | Void | VOID | reason required; audit; reissue links |

### 7.3 Payment

| From | Event | To | Guards |
|---|---|---|---|
| — | Record (rail evidence) | PENDING | amount, method, payer ref, evidence pointer |
| PENDING | Authoritative confirmation event | CONFIRMED | provider callback/verified statement/verified cash+evidence |
| PENDING | Provider failure evidence | FAILED | reason recorded |
| CONFIRMED | Correction | REVERSED | reversal entry; reason; audit; never deleted |

Receipt: issued **only** on CONFIRMED; immutable.

### 7.4 Allocation / Receipt

Allocation: created against (payment, invoice) pairs; append-only; adjusting an
allocation creates a corrective allocation, never edits. Receipt: generated
from confirmed payment + invoice; immutable; re-issue impossible (regenerate
PDF view only).

### 7.5 Maintenance request / work order

| Request: OPEN → ACKNOWLEDGED → IN_PROGRESS → RESOLVED → CLOSED; RESOLVED→IN_PROGRESS on reopen (reason required). |
| Work order: DRAFT → PENDING_APPROVAL (above threshold) → APPROVED → ASSIGNED → IN_PROGRESS → COMPLETED (evidence required) → CLOSED; REJECTED from PENDING_APPROVAL. |

### 7.6 Expense approval (where enabled)

DRAFT → SUBMITTED → APPROVED (within/above threshold routing) → POSTED; REJECTED from SUBMITTED (reason). Posted expenses immutable; corrections via reversal.

### 7.7 Notification delivery

INTENT_CREATED → QUEUED(channel) → SENT(provider ack) → DELIVERED(where evidence exists) / FAILED(reason) → RETRY(queued again, backoff, cap) / SUPPRESSED(consent/opt-out checked at send). One intent, many channel attempts; attempts append-only.

## 8. Acceptance examples & edge cases (must be test cases)

| # | Scenario | Expected behavior |
|---|---|---|
| E-01 | Partial payment on invoice | Balance reduces; state PARTIALLY_PAID; arrears reflects remainder; receipt only after confirmation |
| E-02 | Duplicate provider callback (same reference, twice, concurrent) | One payment record; second is no-op returning original result (idempotency) |
| E-03 | Unmatched payment (no obvious invoice) | Appears in reconciliation unmatched list; staff resolves; matching audited |
| E-04 | Late rent (day +3, +7, +14) | Reminder/escalation per policy; every automated action audit-logged; no auto-penalty unless country policy enables |
| E-05 | Overlapping lease attempt (two managers concurrently activate same unit) | Exactly one activation succeeds; loser receives explicit conflict; unit remains consistent |
| E-06 | Lease renewal | Successor lease linked; history preserved; unit stays occupied seamlessly; schedule continuity |
| E-07 | Disputed payment (tenant claims paid, no evidence) | Payment stays PENDING/UNMATCHED; dispute workflow records claim; no receipt; never auto-resolve |
| E-08 | Failed SMS at arrears day +3 | Intent survives; failure visible; retry with backoff; suppression honored on retry |
| E-09 | Reopened repair after closure | Request returns to IN_PROGRESS with reason; work order can relink; history intact |
| E-10 | Revoked agency access to owner portfolio | Access denied immediately (≤1 session); sensitive reads before revocation were audit-logged; landlord notified per policy |
| E-11 | Mixed-currency portfolio query | Cross-currency sums rejected; report offers recorded-FX conversion or per-currency breakdown |
| E-12 | Workspace A user guesses workspace B URL/IDs | 404/403 indistinguishable; attempt audit-logged (rate-limited) |

## 9. Africa-first regional model

**Platform-wide (code):** workspace model, RBAC, audit, financial records,
state machines, notification intents, adapter ports, i18n framework,
accessibility standards.

**Country profile (data/config):** currency + precision (e.g., KES 2dp; XOF 0dp),
timezone, date/number formats, language(s) (English/Kiswahili where approved),
billable types legality (e.g., late fees), notice-period defaults,
payment-provider adapters and their capabilities, tax-export surface (post-#30
verification only).

**Pilot country:** recommendation recorded in §12 as a decision requiring
product-owner sign-off; no country's rules hard-coded in shared code paths
(FR-REG-05).

## 10. Non-functional requirements

| Area | Requirement |
|---|---|
| Accessibility | WCAG 2.1 AA for portal surfaces; keyboard-complete; screen-reader labels; tested per #14/#28 |
| Low bandwidth / mobile | Core caretaker/tenant flows usable at 2G-class; < 200KB critical path per screen target; visible pending/error states; retry-safe |
| Privacy & data protection | Data minimization; private object storage with scoped, expiring access; no sensitive data in logs/traces/errors; retention per workspace policy; tenant exports consent-scoped (later #23) |
| Auditability | Append-only audit of sensitive actions; financial records immutable with corrections via reversals; reports reproducible |
| Security | Server-side authorization everywhere; deny by default; OIDC sessions; secrets never in code; dependency & secret scanning in local gate (#14) |
| Performance | Dashboards < 3s for 50-unit portfolio; statement < 5 min; no unbounded queries; pagination everywhere |
| Reliability | Idempotent scheduled jobs; retry-safe webhooks; crash-safe imports; backups/restoration per #31 |
| Support & operations | Health checks; structured logging with redaction; incident runbook (#31); support can explain any number from source records |

## 11. Assumptions, unresolved questions, risks

**Decisions requiring product-owner sign-off (blockers where marked):**

| # | Decision | Recommendation | Status |
|---|---|---|---|
| D-1 | **Pilot country** | Kenya (evidence: founding context, Nairobi sibling project, mobile-money ubiquity) | 🔴 BLOCKS #3 final approval & #5 implementation detail |
| D-2 | Identity provider hosting | Keycloak, self-hosted in staging/prod; sandbox uses compose | ⏳ ADR in #3 |
| D-3 | Payment provider for pilot sandbox (record/reconcile adapter) | M-Pesa Daraja sandbox | ⏳ credentials required before #9 |
| D-4 | Kiswahili scope for MVP UI | Core tenant/caretaker surfaces only | ⏳ #28 |
| D-5 | Late-fee/penalty policy default | Off by default; per-country enablement | ⏳ country profile data after D-1 |

**Assumptions (explicitly not facts):** tenants have smartphones for portal
(fallback: notices by SMS); agencies have ≥1 smartphone for caretakers;
electronic rails dominate rent payments; landlords trust agency-held records
if evidence-backed.

**Risks:** provider callback reliability (mitigate: idempotency + reconciliation
loops); low digital literacy among caretakers (mitigate: checklists, photos,
minimal typing); multi-country complexity creep (mitigate: profile-only
variation, per §9); scope expansion into regulated payments (mitigate: §3.3
hard boundary).

## 12. Review & sign-off record

| Role | Name/Handle | Verdict | Date |
|---|---|---|---|
| Product owner | @Roy-Wanyoike | ⏳ pending | — |
| Staff engineer (independent) | review on PR | ⏳ pending | — |
| QA representative | review on PR | ⏳ pending | — |

Sign-off issue comment supersedes this table once recorded.
