# Local Development

## Toolchain

| Tool | Version | Notes |
|---|---|---|
| Go | 1.23.x | Backend (modular monolith). Modules land with issue #4+ |
| Node.js | ≥ 20 (24 tested) | Frontend build tooling |
| bun | 1.3.x | Frontend package manager + scripts |
| PostgreSQL | 16+ | Authoritative datastore. Local server required from #4 onward |
| Keycloak | candidate | OIDC identity provider; ADR pending in #3. Local compose file to be provided with the identity workstream |

## Repository layout (current)

```
.
├── README.md
├── CONTRIBUTING.md
├── .env.example              # placeholders only — copy to .env, never commit
├── .github/
│   └── PULL_REQUEST_TEMPLATE.md
└── docs/
    ├── BRANCH-GOVERNANCE.md  # branches, merges, local release gate
    ├── local-development.md  # this file
    ├── DELIVERY-LOG.md       # append-only delivery record
    └── proposals/phase0/     # superseded early proposals (pending #3)
```

Backend (`server/`), frontend (`web/`), and deployment layout will be added by
the architecture issue #3 — do not pre-create alternative structures.

## Setup

```bash
git clone git@github.com:Roy-Wanyoike/SharkEstate.git
cd SharkEstate
cp .env.example .env   # fill placeholders locally; never commit .env
```

## Command map

The gate commands are normative in [BRANCH-GOVERNANCE.md](./BRANCH-GOVERNANCE.md).
As of bootstrap there is no buildable code yet; the map below grows with each
workstream and is verified at every PR.

| Command | Purpose | Status |
|---|---|---|
| `go test ./...` | Backend unit + integration tests | pending #4 |
| `go vet ./...` | Static analysis | pending #4 |
| `gofmt -l .` | Formatting check | pending #4 |
| `bun install && bun lint` | Frontend lint | pending #3 scaffold |
| `bun build` | Frontend production build | pending #3 scaffold |

## Environment variables

`.env.example` is the single source of truth for variable names. Current
placeholders cover database and identity configuration required by upcoming
workstreams. Secrets belong in your local `.env` (git-ignored) or the hosting
provider's secret store — never in the repository.
