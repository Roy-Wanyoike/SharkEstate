# Branch Governance & Local Release Gate

## Persistent branches

| Branch | Role | Protection |
|---|---|---|
| `main` | Production. Contains only verified, released states. | PRs required · no force-push · no deletion · linear history · admin enforced |
| `dev` | Development integration branch. Default working target for all PRs. | Same rules as `main` |

Both branches are persistent and non-deletable. No other persistent branches
are permitted; feature branches (`feat/*`, `fix/*`, `docs/*`) are created from
`origin/dev` and deleted after their PR merges.

Verified configuration (set via the GitHub API at bootstrap, issue #2):
`allow_force_pushes: false`, `allow_deletions: false`,
`required_linear_history: true`, `enforce_admins: true`,
`required_pull_request_reviews` with `dismiss_stale_reviews: true`.

**Approval policy decision:** required approving reviews is currently `0` on
GitHub because the team has a single GitHub account today; review evidence is
nevertheless **mandatory** and lives in each PR (independent Staff Engineer
review + Principal QA checklist in the PR template, mirrored in
`docs/DELIVERY-LOG.md`). Escalation: as soon as a second reviewer account is
available, set `required_approving_reviews: 1` on both branches. This is a
recorded, time-boxed exception — not a license to self-merge silently.

## Merge policy

- Squash-merge only. Linear history is enforced; merge commits are rejected by
  branch protection.
- PRs target `dev`. Promotion from `dev` to `main` is a separate, controlled
  release PR (`release/<date>` or `release/<version>`), never a direct push.
- `Closes #N` auto-close only fires on default-branch (`main`) merges. Our PRs
  target `dev`, so issues are **closed manually** by Principal QA after
  verifying acceptance criteria post-merge. Reference issues with `Refs #N`.

## Local release gate (no GitHub Actions)

This repository intentionally contains **no GitHub Actions workflow files**
(account billing constraint). The gate is local, documented, and mandatory:

1. `git fetch origin && git rebase origin/dev` — branch is current, linear.
2. `gofmt -l .` / project linters — clean (commands expand as workstreams land;
   keep this file updated with each new tool).
3. `go test ./...` — all packages pass (backend workstream).
4. `pnpm lint && pnpm build && pnpm test` — frontend workstream equivalent
   (to be recorded precisely when the Next.js app scaffolds in #3).
5. Migration review — any schema change ships with an up **and** documented
   rollback posture.
6. Secret scan — `git diff origin/dev..HEAD | grep -iE '(token|secret|password|api[_-]?key)'`
   or equivalent tooling; no matches outside test fixtures.
7. Evidence recorded in the PR body. A PR without pasted gate output is not
   reviewable.

The release PR `dev → main` additionally requires: all merged issue acceptance
criteria re-verified, backup/restore posture confirmed (issue #14/#31 when
active), rollback plan stated, and Principal QA verdict recorded in
`docs/DELIVERY-LOG.md`.

## Enforcement reality check

Branch protection is verified active on both branches (API-verified at
bootstrap). If protection is ever found disabled, treat it as a **P0 incident**:
stop merges, restore protection, and record the incident in the delivery log.
