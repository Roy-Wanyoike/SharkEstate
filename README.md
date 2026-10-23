# SharkEstate 🦈

> Real estate management, simplified. Property **operations** platform for Kenyan
> landlords and agencies — leases, rent collection via M-Pesa, maintenance, and
> owner reporting.

## Positioning — read this first

SharkEstate is **not** a listings marketplace. It is the **back office**:

| Concern | Delima Realtors (sibling project) | SharkEstate (this repo) |
|---|---|---|
| Audience | Buyers, renters, agents doing sales | Landlords, property managers, accountants |
| Jobs | Browse, enquire, lead capture, marketing | Lease tenants, collect rent, fix things, report to owners |
| Money event | A sale commission | Monthly recurring rent, deposits, service charges |
| Cadence | One-off transactions | Perpetual monthly cycles |

Keep the two separate. Integrate later (SharkEstate can import a tenant from a
Delima lease handover), but do not blend the codebases or data models. Trying to
be a marketplace and a management system at once is how property products die
before launch.

## The one-paragraph product thesis

Kenyan property management still runs on WhatsApp, Excel and cash-at-the-office.
The pain is not finding tenants — it is knowing **who owes what, when**, chasing
it, proving it to the owner, and not losing receipts. SharkEstate wins by making
the monthly rent cycle effortless: automatic invoicing, M-Pesa-first payments
with automatic reconciliation, arrears that escalate themselves, and owner
statements generated in one click.

## Planned stack

- **Next.js 16 (App Router) + TypeScript strict** — one deployable, modular monolith
- **PostgreSQL + Prisma** — financial data needs transactions, not SQLite
- **NextAuth v4** — credentials + Google; org-scoped RBAC
- **TanStack Query + Zustand + shadcn/ui + Tailwind** — standard UI stack
- **M-Pesa Daraja API** — STK Push + C2B confirmation callbacks (first-class, not an add-on)
- **Africa's Talking SMS** — rent reminders and arrears notices (email alone will not reach Kenyan tenants)
- **S3-compatible storage (Cloudflare R2)** — property photos, lease PDFs, receipts
- **Zod** — validation at every boundary

See [ARCHITECTURE.md](./ARCHITECTURE.md), [ROADMAP.md](./ROADMAP.md) and
[docs/DOMAIN-MODEL.md](./docs/DOMAIN-MODEL.md) for the full opinion.

## Status

Phase 0 — design foundation. Code scaffold lands next on `main`.

## Repository conventions

- Trunk-based: short-lived branches → PR → squash into `main`
- Conventional commits (`feat:`, `fix:`, `chore:`)
- CI: lint + typecheck on every PR (add GitHub Actions at Phase 1 kickoff)
- **Never commit secrets.** Tokens live in GitHub Actions secrets / `.env`
  (git-ignored). If a token ever appears in history, rotate it immediately.
