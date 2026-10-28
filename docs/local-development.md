# Local Development

## Toolchain

| Tool | Version | Notes |
|---|---|---|
| Go | 1.23.x | Backend (modular monolith). Modules land with issue #4+ |
| Node.js | ≥ 20 (24 tested) | Frontend build tooling |
| bun | 1.3.x | Frontend package manager + scripts |
| PostgreSQL | 16+ | Authoritative datastore. Local server required from #4 onward (docker compose ships with #4; rootless environments may use embedded server binaries — any vanilla PostgreSQL 16 works) |
| Keycloak | candidate | OIDC identity provider; ADR pending in #3. Local compose file to be provided with the identity workstream |

## Repository layout (current)

```
.
├── README.md
├── CONTRIBUTING.md
├── .env.example              # placeholders only — copy to .env, never commit
├── .gitignore                # ignores .env*, builds, logs, local db files
├── .github/
│   └── PULL_REQUEST_TEMPLATE.md
├── scripts/
│   └── quality-gate.sh       # normative local quality gate (issue #14)
└── docs/
    ├── BRANCH-GOVERNANCE.md  # branches, merges, local release gate
    ├── local-development.md  # this file
    ├── DELIVERY-LOG.md       # append-only delivery record
    ├── quality/              # test strategy, threat register, release checklist (#14)
    └── proposals/phase0/     # superseded early proposals (pending #3)
```

Backend (`server/`), frontend (`web/`), and deployment layout will be added by
the architecture issue #3 — do not pre-create alternative structures.

## Setup

```bash
git clone https://github.com/Roy-Wanyoike/SharkEstate.git
cd SharkEstate
cp .env.example .env   # fill placeholders locally; never commit .env
```

## Command map

The gate commands are normative in [BRANCH-GOVERNANCE.md](./BRANCH-GOVERNANCE.md).
As of bootstrap there is no buildable code yet; the map below grows with each
workstream and is verified at every PR.

| Command | Purpose | Status |
|---|---|---|
| `scripts/quality-gate.sh` | Runs every applicable quality gate (G1–G7) and prints a PASS/FAIL/SKIP summary | **active** (issue #14) |
| `go test ./...` | Backend unit + integration tests | pending #4 (auto-run by gate) |
| `go vet ./...` | Static analysis | pending #4 (auto-run by gate) |
| `gofmt -l .` | Formatting check | pending #4 (auto-run by gate) |
| `govulncheck ./...` | Go dependency vulnerability scan | pending #4 (auto-run by gate when installed) |
| `bun install && bun lint` | Frontend lint | pending web scaffold (auto-run by gate) |
| `bun build` | Frontend production build | pending web scaffold (auto-run by gate) |
| `bun audit` | Frontend dependency audit | pending web scaffold (auto-run by gate) |

The gate script auto-detects which workstreams exist (go.mod, web/package.json,
migrations) and reports everything else as SKIP with a reason — a gate run is
valid evidence even while the repository is docs-only.

## Environment variables

`.env.example` is the single source of truth for variable names. Current
placeholders cover database and identity configuration required by upcoming
workstreams. Secrets belong in your local `.env` (git-ignored) or the hosting
provider's secret store — never in the repository.
