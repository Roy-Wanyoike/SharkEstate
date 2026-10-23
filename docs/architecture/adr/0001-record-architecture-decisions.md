# ADR-0001: Record architecture decisions

- Status: Accepted
- Date: 2026-10-23
- Deciders: Principal Engineer; ratified via issue #3 review

## Context
Multiple consequential technology and boundary decisions must be made and
challengeable over time, with a trail reviewers and future engineers can
follow.

## Decision
Adopt Architecture Decision Records (Nygard format: Status/Context/Decision/
Consequences). Every material, hard-to-reverse decision gets an ADR in
`docs/architecture/adr/`; ADRs are immutable once Accepted — superseding ADRs
reference their predecessor.

## Consequences
Slight documentation overhead per decision; in exchange, traceable rationale,
reviewable changes to architecture, and a training artifact for new engineers.
