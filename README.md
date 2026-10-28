# SharkEstate 🦈

> Property management, simplified. An Africa-first, multi-country residential
> property management platform for agencies, landlords, caretakers, and tenants.

SharkEstate helps property agents, landlords, and caretakers manage properties
and tenant relationships with less manual work, while tenants get a clear
self-service channel. See GitHub issue [#1](https://github.com/Roy-Wanyoike/SharkEstate/issues/1)
for the authoritative product direction and release scope.

## Project status

**Phase 0 — governance & design foundation.** No production code has been
implemented yet. Delivery is issue-first: every change traces to a GitHub
issue, ships through a pull request into `dev`, and is promoted to `main`
only through the documented release gate.

| Document | Purpose |
|---|---|
| [CONTRIBUTING.md](./CONTRIBUTING.md) | How to contribute: branches, PRs, review chain |
| [docs/BRANCH-GOVERNANCE.md](./docs/BRANCH-GOVERNANCE.md) | `dev` → `main` policy, protection rules, local release gate |
| [docs/local-development.md](./docs/local-development.md) | Environment setup and the command map |
| [docs/DELIVERY-LOG.md](./docs/DELIVERY-LOG.md) | Append-only engineering delivery record |
| [docs/architecture/](./docs/architecture/ARCHITECTURE.md) | Architecture blueprint + ADRs (issue #3) |
| [docs/quality/](./docs/quality/TEST-STRATEGY.md) | Test strategy, threat register, release checklist (issue #14) |
| [scripts/quality-gate.sh](./scripts/quality-gate.sh) | Normative local quality gate — run before every PR |
| [docs/proposals/phase0/](./docs/proposals/phase0/README.md) | Early design proposals — **superseded, pending #3** |

## Approved technology baseline (ADR-0001..0011, signed off 2026-10-28)

- **Backend:** Go (modular monolith with explicit domain boundaries)
- **Frontend:** Next.js + TypeScript + shadcn/ui
- **Database:** PostgreSQL — authoritative store for application and financial records
- **Identity:** OIDC-compatible integration (Keycloak is the current candidate)
- **APIs:** Versioned REST with OpenAPI specifications
- **Observability:** OpenTelemetry (metrics, logs, traces)

The blueprint and ADRs live in [docs/architecture/](./docs/architecture/ARCHITECTURE.md)
(pending final approval through [#3](https://github.com/Roy-Wanyoike/SharkEstate/issues/3)).
Do not start feature implementation before that approval, and do not introduce
alternative frameworks, databases, or identity systems without a documented
ADR decision.

## Governance essentials

- `dev` is the integration branch; `main` is production. Both are protected:
  pull requests required, force pushes and deletions disallowed, linear
  history enforced.
- Never push directly to `main` or `dev`. Open a feature branch from `dev`,
  link an issue, and pass the local quality gate before requesting review.
- No GitHub Actions workflow files are permitted in this repository
  (account billing constraint). Validation is a documented local gate — see
  [docs/BRANCH-GOVERNANCE.md](./docs/BRANCH-GOVERNANCE.md).
- Never commit secrets, credentials, or production data. `.env` files are
  git-ignored; `.env.example` documents required variables with placeholders.
