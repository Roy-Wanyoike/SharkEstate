# ADR-0005: Next.js 16 + TypeScript + shadcn/ui frontend on versioned REST

- Status: Accepted (pending issue #3 final approval)
- Date: 2026-10-23

## Context
Role-based dashboards (admin/manager/landlord/caretaker/tenant/contractor),
mobile-first + low-bandwidth targets (< 200 KB critical path), accessible UI
(WCAG 2.1 AA), and a single web codebase for portal + back office.

## Decision
One **Next.js 16 (App Router) + TypeScript strict + shadcn/ui + Tailwind**
frontend consuming the versioned Go REST API (`/api/v1`). Server components
for authenticated data fetch; client components for interactions; TanStack
Query for client-side server state; Zod for form/API boundary validation.
Frontend holds **no business rules** — authorization-aware routing renders
what the API would deny anyway, but the API remains the enforcement point.

## Consequences
One deployable frontend; design-system consistency; performance budgets are
enforceable in CI-equivalent local gate (#14). No SSR of financial data into
shared caches — authenticated pages render per-session (no full-page cache).
