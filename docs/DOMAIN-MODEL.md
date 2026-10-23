# SharkEstate — Domain Model

The domain has a hard backbone. Get these five entities right and everything
else is configuration.

## Entity map

```
Organization ─┬─< Membership >─ User            (staff; RBAC)
              ├─< Property ─< Unit ─< Lease >─< Tenant
              │                      │
              │                      ├─< Invoice ─< InvoiceItem
              │                      │      └─< Payment (append-only)
              ├─< MaintenanceRequest >─ Unit
              ├─< Document (polymorphic attach)
              └─< AuditLog
```

## The five backbone rules

1. **Property ≠ Unit.** A property holds many units. Every lease, invoice and
   maintenance ticket attaches to a **Unit** (or to the property only for
   whole-property work). Modeling rent on the property level is the classic
   first mistake — it collapses the moment a landlord has bedsitters, commercial
   stalls and residential blocks in one compound.
2. **Lease is the contract object**, not the tenant. Money flows
   Lease → Invoice → Payment. A tenant can have history across many leases; a
   unit can have many leases over time (one **active** at a time — enforce in a
   transaction).
3. **Tenants are people, leases link them.** `Lease ↔ Tenant` is many-to-many
   (couples, guarantors, company tenancies with directors).
4. **Invoices are immutable once issued.** Corrections happen via credit notes
   (v2) or void-and-reissue, both audit-logged.
5. **Payments are append-only.** Correction = reversal entry. Balance is always
   derived, never stored.

## Status machines

```
Unit:      VACANT → OCCUPIED → NOTICE → VACANT
                    ↘ MAINTENANCE ↗      (never occupied + maintenance)

Lease:     DRAFT → ACTIVE → EXPIRING → RENEWED | EXPIRED | TERMINATED
                    (EXPIRING = endDate within 60d; cron flips these)

Invoice:   DRAFT → ISSUED → PARTIALLY_PAID → PAID
                       ↘ OVERDUE (dueDate + 1, cron)    VOID (with reason)

MaintenanceRequest:
           OPEN → ACKNOWLEDGED → IN_PROGRESS → RESOLVED → CLOSED
           priority: LOW | MEDIUM | HIGH | EMERGENCY
```

State transitions live in one module function each (e.g. `confirmLease()`) —
never inline `prisma.update({ status: ... })` scattered across routes. The
state machine is the API.

## Kenya-context fields (build them in from day one)

- `Tenant`: `phone` (required, E.164), `nationalId`, `krapin?` (commercial tenants)
- `Lease`: `noticePeriodDays` (default 30 per common Kenyan practice),
  `depositMonths` (usually 1–2), `billables` (rent / serviceCharge / water /
  garbage toggles with amounts)
- `Payment.method`: `MPESA | BANK | CASH`; M-Pesa path stores
  `mpesaReceipt`, `phone`, raw callback JSON
- All money: `Decimal(14,2)` + `currency` (default `KES`)
- Addresses: `county` + `city/estate` + `building` — skip Western-style ZIP

## Seed demo scenario (used for the golden-path test)

- Org: "Shark Estates Ltd"
- Property: "Shark Plaza, Kilimani" — 12 units (2 bedsitters, 6 one-bed, 4 two-bed)
- 3 leases in different states: paid-up, 1 month arrears (drives the arrears
  ladder), ending in 45 days (drives the expiry workflow)
- One open emergency maintenance ticket (burst pipe)
