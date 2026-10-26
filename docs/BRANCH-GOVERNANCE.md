# Branch Governance & Local Release Gate

## Persistent branches

| Branch | Role | Protection |
|---|---|---|
| `main` | Production. Contains only verified, released states. | PRs required · no force-push · no deletion · linear history · admin enforced |
| `dev` | Development integration branch. **Repository default branch** (flipped from `main` via API on 2026-10-23, issue #2). Default working target for all PRs. | Same rules as `main` |

Both branches are persistent and non-deletable. No other persistent branches
are permitted; feature branches (`feat/*`, `fix/*`, `docs/*`) are created from
`origin/dev` and deleted after their PR merges.

Verified configuration (set via the GitHub API at bootstrap, issue #2, and
confirmed by live denial test — a force-push against `dev` was rejected by the
protected-branch hook): `allow_force_pushes: false`, `allow_deletions: false`,
`required_linear_history: true`, `enforce_admins: true`,
`required_pull_request_reviews` with `dismiss_stale_reviews: true` and
`required_approving_review_count: 0`.

> Bootstrap note: the first protection call used a misspelled request key and
> GitHub silently coerced the approval count to 1. Detected during Principal
> verification, re-set with the correct field name, and re-verified — recorded
> here as a reminder that protection claims must be **verified, not assumed**.

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
- Issues are closed **only after Principal QA verifies acceptance criteria
  against the merged code**. Do not use auto-close keywords (`Closes #N`,
  `Fixes #N`) in PRs — closing is a deliberate QA act, not a merge side effect.
  Reference issues with `Refs #N` and close them manually with an evidence
  comment.

## Local release gate (no GitHub Actions)

This repository intentionally contains **no GitHub Actions workflow files**
(account billing constraint). The gate is local, documented, and mandatory:

1. `git fetch origin && git rebase origin/dev` — branch is current, linear.
2. `gofmt -l .` / project linters — clean (commands expand as workstreams land;
   keep this file updated with each new tool).
3. `go test ./...` — all packages pass (backend workstream).
4. `bun lint && bun run build && bun test` — frontend workstream equivalent
   (to be recorded precisely when the Next.js app scaffolds in #3).
5. Migration review — any schema change ships with an up **and** documented
   rollback posture.
6. Secret scan — value-based pattern over the full diff (matches assigned
   credential-like values, ignores prose and `CHANGE_ME` placeholders):
   `git diff origin/dev..HEAD | grep -inE "(password|secret|token|api[_-]?key)[\"' ]*[:=][\"' ]*[A-Za-z0-9+/_-]{12,}"`
   — must return no matches (a deliberate exception, e.g. a redacted fixture,
   must be explained in the PR body).
7. Evidence recorded in the PR body. A PR without pasted gate output is not
   reviewable.

**Gate executor (issue #14):** `scripts/quality-gate.sh` runs every
applicable gate above in one reproducible command and is the normative
pre-PR check — run it from the repository root and paste its summary into the
PR body. Individual commands remain documented here for transparency and
onboarding. Gates auto-activate as workstreams land (a `SKIP` is an explicit,
loud deferral — never a silent pass); a new gate is added to the script and to
[TEST-STRATEGY.md](./quality/TEST-STRATEGY.md) in the same PR that introduces
the code it checks.

The release PR `dev → main` additionally requires: all merged issue acceptance
criteria re-verified, backup/restore posture confirmed (issue #14/#31 when
active), rollback plan stated, and Principal QA verdict recorded in
`docs/DELIVERY-LOG.md`.

## Enforcement reality check

Branch protection is verified active on both branches (API-verified at
bootstrap). If protection is ever found disabled, treat it as a **P0 incident**:
stop merges, restore protection, and record the incident in the delivery log.
