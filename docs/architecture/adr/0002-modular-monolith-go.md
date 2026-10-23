# ADR-0002: Go modular monolith with hexagonal module boundaries

- Status: Accepted (pending issue #3 final approval)
- Date: 2026-10-23

## Context
Team of 1–5; product scope spans identity, portfolio, leases, billing,
payments, maintenance, notifications, reporting across countries. Microservices
would add operational load with no scaling payoff at this size; a framework-y
fullstack (e.g., single Next.js app owning domain logic) would bury financial
invariants in a web framework and complicate long-running jobs and strict
transactions.

## Decision
Backend in **Go**, single deployable, organized as domain modules (see
ARCHITECTURE.md §2) with hexagonal boundaries: modules expose service
interfaces (ports) and typed domain events; adapters own HTTP, DB, providers.
Rules: no cross-module table access; business rules out of HTTP handlers and
out of the frontend; authorization enforced at API layer and re-checked in
domain command entry points.

## Consequences
One operational unit to deploy/observe; strong testability of domain logic;
discipline required to keep boundaries clean (enforced by code-review
checklist and architecture tests). Extraction to services remains possible
without rewrite if triggers (ARCHITECTURE.md §9) are met.
