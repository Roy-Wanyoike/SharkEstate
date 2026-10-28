# ADR-0010: Pilot country is Kenya

| | |
|---|---|
| Date | 2026-10-28 |
| Status | Accepted |
| Decides | PRD open decision D-1 (issue #3, PRD §11) |

## Context

The platform is Africa-first with country behavior isolated in the regional
module (ADR-0003/§6 of the blueprint), so the pilot choice must not leak into
shared code. D-1 blocked final approval of #3 and implementation detail of #5.
Evidence recorded in #1: founding market context, the Nairobi sibling project
(New-Delima-Realtors), and mobile-money ubiquity (M-Pesa) as the dominant
rent-collection rail.

## Decision

Kenya is the pilot country. The product owner authorized execution via the
Engineering Execution Mandate (2026-10-28), adopting the recommendation
recorded in PRD §11.

## Consequences

- #5 seeds a Kenya country profile (KES, Africa/Nairobi, en/en-KE formats,
  Swahili secondary for surfaced strings per D-4) as data, never code.
- The first payment record/reconcile adapter targets M-Pesa Daraja sandbox
  (D-3: credentials required before #9 wires it; the port and simulator ship
  without it).
- Kenya tenancy/notice/tax specifics: verified through #30 before any
  compliance behavior ships (T-14 gate) — this ADR does not encode tax rules.
- Reversal: a second country is a new profile row + adapter registration —
  no rewrite (blueprint §6).
