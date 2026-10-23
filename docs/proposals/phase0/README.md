# Phase 0 Proposals — SUPERSEDED (pending #3)

> ⚠️ **Status: superseded.** These documents were an early single-agent
> proposal written before the backlog in issues #1–#31 existed. They assume a
> **Next.js fullstack** architecture (NextAuth, Prisma, SQLite-to-Postgres),
> which conflicts with the approved baseline recorded in the master execution
> prompt and issue #3: **Go backend + Next.js/TypeScript/shadcn frontend +
> PostgreSQL + OIDC identity + modular monolith**.
>
> They are retained here for historical context only. **Do not implement from
> these documents.** The authoritative architecture is the blueprint and ADRs
> produced under issue #3; the authoritative product requirements are issues
> #1 and #15.
>
> — Recorded in docs/DELIVERY-LOG.md, 2026-10-23.

| Document | Was | Conflict with approved baseline |
|---|---|---|
| `ARCHITECTURE.md` | Early architecture opinion | Next.js fullstack, Prisma-first, NextAuth, Kenya-hardcoded |
| `ROADMAP.md` | Early phase plan | Phase structure predates issues #1–#31 dependency graph |
| `DOMAIN-MODEL.md` | Early entity sketch | Single-workspace assumption; Kenya-specific hardcoding vs country-profile model in #5 |
| `API-DESIGN.md` | Early REST sketch | NextAuth session assumptions; no versioned `/v1` contract or OpenAPI plan |
| `schema-proposal.prisma` | Early schema sketch | Prisma-centric; final persistence design comes from #3 ADRs |
