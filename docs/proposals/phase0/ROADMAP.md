# SharkEstate — Roadmap

Discipline rule: **each phase ends with something a landlord can use to make
money.** No phase ships infrastructure alone.

## Phase 0 — Foundation (done when this repo has a scaffold)

- [x] Architecture + domain model + schema proposal (this repo)
- [ ] Next.js 16 scaffold: Tailwind, shadcn/ui, Prisma + Postgres, NextAuth,
      TanStack Query, Zod, ESLint
- [ ] CI: lint + typecheck on PRs
- [ ] Org + user + membership model wired to auth

## Phase 1 — Back-office MVP (the 6-week target)

The landlord/manager can run rent collection end-to-end:

1. Properties → Units CRUD (bulk unit creation: "12 units, prefix A, bedsitter")
2. Tenants CRUD (phone-first)
3. Leases: create, activate (enforces one active lease per unit), terminate
4. **Monthly invoice run** — cron generates rent + billables invoices
5. Payments: record M-Pesa (manual receipt entry), bank, cash → balances update
6. Dashboard: rent roll, occupancy %, arrears list, this-month collections
7. Maintenance tickets: log, status flow, cost tracking
8. Owner statement PDF per property (the selling document)

Cut list for this phase (do NOT sneak in): tenant portal, automated STK push,
SMS automation, penalties/late fees, credit notes, expense tracking.

## Phase 2 — Money automation

- M-Pesa Daraja STK Push from payment screen
- C2B confirmation webhook → auto-reconcile → auto-receipt SMS
- Arrears ladder: reminder (day +3), final notice (day +7), escalation flag
  (day +14) — all audit-logged
- Lease expiry workflow: 60-day warnings, renewal flow (supersedes chain)
- Deposits: receipt on lease start, refund workflow with deductions
- Africa's Talking SMS templates + delivery log

## Phase 3 — Portals & reporting

- Tenant portal: balance, statements, pay button, maintenance requests
- Landlord/owner read-only portal (multi-property owners see portfolio)
- Deeper reports: arrears aging, vacancy trend, per-unit profitability,
  maintenance spend, monthly comparisons
- Export: CSV everywhere, QuickBooks/Zoho-ready formats

## Phase 4 — Integrations & scale

- Delima Realtors handover (lead → tenant import)
- Withholding tax + KRA-facing reports
- Bulk SMS campaigns, WhatsApp template messages
- Expense tracking & vendor payments
- E-signatures on lease PDFs

## Definition of done (every phase)

- Golden-path Playwright test green
- Money flows covered by unit tests
- Lighthouse ≥ 90 on dashboards
- No P0/P1 bugs open; worklog updated in-repo
