# SharkEstate — Architecture Opinion

## 1. Shape: modular monolith, not microservices

One Next.js 16 App Router deployment. Internal code organised by **domain
module**, not by framework layer:

```
src/
  app/                    # routes only — thin
  modules/
    properties/           # Property + Unit: queries, mutations, schemas, UI pieces
    leases/               # Lease lifecycle, renewals, amendments
    billing/              # Invoices, payments, reconciliation, statements
    maintenance/          # Tickets, vendors
    notifications/        # SMS + email sending, templates
    mpesa/                # Daraja client, STK push, C2B webhook handling
    auth/                 # NextAuth config, RBAC helpers
  lib/                    # db client, money helpers, dates, audit
```

Rules that keep the monolith healthy:

- Modules talk to each other **through exported service functions only**, never
  by reaching into another module's tables ad hoc.
- Every route handler validates input with **Zod** and returns typed errors.
- API routes (`/api/**`) are the only place Prisma is touched from the wire;
  client components never import `db`.

Rationale: a team of 1–5 shipping a vertical SaaS does not need microservices.
It needs boundaries it can split later. Domain modules give you that without the
operational tax.

## 2. Multi-tenancy: single database, org-scoped rows

`Organization` is the tenant root. Every domain table carries `orgId` with a
**composite unique index where relevant** (e.g. `@@unique([orgId, slug])`) and
**every query goes through a helper that injects the org filter**:

```ts
// lib/org-scope.ts
export function scoped<T extends { orgId: string }>(
  tx: PrismaClient, orgId: string
) { /* returns a proxy that adds where: { orgId } to every read/write */ }
```

Do not use row-level security or separate schemas in v1 — operational overhead
outweighs the isolation benefits at this scale. Do write the scoping helper
once, on day one, so no route ever hand-rolls `where: { orgId }` and forgets it.
Cross-tenant data leaks are the #1 SaaS kill-shot; make the safe path the
default path.

## 3. Money: the non-negotiables

These are the decisions that separate a real PMS from a demo:

1. **Never floats.** All amounts are `Decimal(14,2)` in Postgres, handled as
   strings in the API layer, formatted at the edge. Currency is a column
   (`default "KES"`), never a global constant.
2. **Append-only payments.** Payments are never updated or deleted — a mistake
   is a `REVERSAL` payment entry. The invoice balance is always *derived*
   (`sum(invoiceItems) - sum(confirmedPayments)`), never stored-and-mutated.
3. **Idempotent webhooks.** M-Pesa redelivers callbacks. Every callback handler
   keys on the transaction reference and must be safe to run twice. Store the
   raw payload (`Json`) before processing.
4. **Audit log on every money event.** Invoice issued, payment confirmed,
   reversal, lease amendment — actor, timestamp, before/after snapshot.
5. **Deposits are liabilities, not revenue.** Separate invoice type; refund flow
   is a first-class screen, not a manual journal entry.

## 4. The rent engine (the heart of the product)

- A **cron job (Vercel Cron / GitHub Actions scheduled workflow in v1)** runs
  daily: for every active lease whose billing day is today (or whose period
  rolled over), generate the month's invoice — rent + recurring service charge,
  water, garbage per the lease's billables.
- Invoice issuance emits an SMS + email to tenants with a payment link.
- STK Push is triggered from the tenant payment screen; C2B confirmation
  webhook confirms, matches reference → invoice, applies payment, flips
  invoice status, notifies the manager.
- Arrears ladder (configurable per org): day +3 reminder → day +7 "final
  notice" SMS → day +14 flag for human escalation. Every step is an
  `AuditLog`-ed automated action.
- **Owner statements** are generated monthly per property owner: income,
  expenses, occupancy, arrears. PDF export. This is the report that sells the
  product to landlords.

## 5. Kenya-first specifics

- Timezone `Africa/Nairobi` everywhere; render dates as `dd MMM yyyy`.
- Phone numbers are the primary tenant identifier (E.164, `+254…`) — collect
  phone before email, SMS before email.
- M-Pesa before cards. Cards/bank transfer are secondary rails.
- Kenya-specific billables: service charge, water, garbage are normal monthly
  line items alongside rent — model them as first-class invoice item types.
- Deposits: respect notice periods and deposit-return norms in lease terms
  (store them structured: `noticePeriodDays`, `depositDays`), so the system can
  compute refund timelines, not just store text.
- Later (v2): landlord withholding-tax report (10% resident landlords), KRA
  PIN on landlord profiles, eTIMS-ready invoice export.

## 6. Background work

v1 keeps it boring: scheduled GitHub Action (or Vercel Cron) hitting an
authenticated `/api/jobs/daily` endpoint that runs idempotent daily jobs:
invoice generation, arrears ladder, lease expiry checks, statement snapshots.
Queue infra (BullMQ + Redis) is deferred until there is a real need — likely
bulk SMS fan-out.

## 7. Auth & RBAC

NextAuth v4, credentials + Google. Roles at org level:
`OWNER` (product owner of the org account), `MANAGER`, `AGENT`, `ACCOUNTANT`,
`TENANT` (portal-only, v2). Enforce via middleware on `/api` + server-component
checks — never trust the UI. Tenant portal lands after the back office works;
managers are the paying users, tenants are the beneficiaries.

## 8. Testing & quality bar

- Unit tests for the money logic (invoice generation, balance derivation,
  reversal, webhook idempotency) — Vitest. This is where bugs cost trust.
- Playwright golden path: create org → property → unit → tenant → lease →
  generate invoice → record M-Pesa payment → see zero balance.
- No money-flow PR merges without a test touching the change.

## 9. What we deliberately do NOT build in v1

- Double-entry general ledger / full accounting (export instead; integrate an
  accountant-friendly CSV + later QuickBooks/Zoho sync)
- Chat/messaging (WhatsApp deep-links are enough)
- Mobile apps (responsive web first; the PWA can come later)
- A public marketplace/listings side (that is Delima's job)
