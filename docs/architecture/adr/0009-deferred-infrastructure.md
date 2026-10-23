# ADR-0009: Deferred/rejected infrastructure with trigger conditions

- Status: Accepted (pending issue #3 final approval)
- Date: 2026-10-23

## Context
Issue #3 mandates introducing heavier infrastructure only when justified by
measured requirements; the PRD forbids speculative complexity.

## Decision
| Technology | Stance | Trigger to introduce |
|---|---|---|
| Redis caching | Deferred | Measured read-path p95 misses on dashboards after profiling at pilot scale |
| Temporal (durable workflows) | Deferred | > 3 long-running, multi-day, human-step workflows beyond the arrears ladder/notifications |
| NATS JetStream / event mesh | Deferred | Second service extraction, or fan-out that in-process transactional events cannot serve |
| Microservices | Rejected for MVP | Team > ~8 engineers contending on one deployable (see ARCHITECTURE.md §9) |
| Supabase / BaaS | Rejected | Financial integrity + workspace isolation + append-only requirements demand owned Postgres and application-role privileges |
| Read replicas / reporting store | Deferred | Statement generation p95 breach at 10× pilot scale |

## Consequences
Simplest operable system now; each deferral has an objective trigger so the
decision to add infrastructure is evidence-driven, not preference-driven.
