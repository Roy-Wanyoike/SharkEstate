# Contributing to SharkEstate

Delivery is **issue-first**. Every change must trace to a GitHub issue, ship
through a pull request into `dev`, and pass the local quality gate before
review. No direct pushes to `main` or `dev` — both branches are protected.

## The delivery chain

```
Existing issue → verified scope & dependencies
  → feature branch from dev (feat/<issue>-<slug>)
  → implementation + tests + docs
  → local quality gate (see docs/BRANCH-GOVERNANCE.md)
  → pull request into dev (one PR per issue, linked reference)
  → independent Staff Engineer review
  → Principal Engineer QA & acceptance verification
  → squash-merge into dev
  → controlled, verified release to main
```

## Rules

1. **One issue, one PR.** Do not bundle unrelated issues. Reference the issue
   in the PR body (`Refs #N`); issues are closed manually after Principal QA
   confirms the acceptance criteria — closing is a deliberate QA act, never a
   merge side effect, so auto-close keywords (`Closes #N`) are not used.
2. **Branch naming:** `feat/<issue>-<short-slug>`, `fix/<issue>-<short-slug>`,
   `docs/<issue>-<short-slug>`. Branches are created from `origin/dev` and
   deleted after merge.
3. **Never force-push** to any branch, and never push directly to `main` or
   `dev`. Branch protection enforces this; do not ask for exemptions.
4. **No GitHub Actions workflow files.** The repository constraint is an
   account billing constraint. Validation runs locally — document any new
   command in `docs/BRANCH-GOVERNANCE.md` and `docs/local-development.md`.
5. **No secrets.** Never commit credentials, tokens, or production data.
   `.env` files are git-ignored. If a secret is ever committed, rotate it
   immediately and record the incident in `docs/DELIVERY-LOG.md`.
6. **Architecture discipline.** The approved baseline is recorded in #3 (once
   approved). Do not introduce new frameworks, databases, identity systems, or
   infrastructure without a written ADR and product-owner approval.
7. **Financial integrity is non-negotiable.** Money-touching changes require
   explicit transactions, idempotency evidence, reversal handling, and test
   coverage of failure cases — not just the happy path.

## Pull requests

Use [.github/PULL_REQUEST_TEMPLATE.md](./.github/PULL_REQUEST_TEMPLATE.md).
A PR is merge-ready only when:

- [ ] Scope matches the linked issue's acceptance criteria.
- [ ] Local quality gate passes (commands and output recorded in the PR).
- [ ] Tests cover new behavior **and** relevant failure/denial cases.
- [ ] Docs and operational notes are updated where affected.
- [ ] An independent reviewer (not the author) has reviewed and approved.
- [ ] Principal QA has verified actual behavior against the issue.

## Issues

- Issues are the unit of scope. If an issue lacks acceptance criteria,
  dependencies, security considerations, or QA expectations, update the issue
  **before** starting the work.
- Dependencies are recorded in each issue body. Respect them; do not start an
  issue whose prerequisites are open.
- Keep statuses honest: "code written" is not "verified"; a passing build is
  not a delivered feature.
