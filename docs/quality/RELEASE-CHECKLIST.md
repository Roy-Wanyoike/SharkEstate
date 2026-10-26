# SharkEstate — Release Checklist

| | |
|---|---|
| Version | 0.1.0 |
| Issue | [#14 QUALITY](https://github.com/Roy-Wanyoike/SharkEstate/issues/14) |
| Policy base | [BRANCH-GOVERNANCE](../BRANCH-GOVERNANCE.md) — dev→main promotion is a controlled release PR, never a direct push |

## When this checklist applies

Every promotion PR from `dev` to `main` (branch naming `release/<date>` or
`release/<version>`, squash-merge, precedent: PR #38). Feature PRs into `dev`
use the [PR template](../../.github/PULL_REQUEST_TEMPLATE.md) and the
[quality gate](./TEST-STRATEGY.md) only.

## Promotion checklist (Principal QA owns the verdict)

1. **Scope inventory** — list every issue delivered since the previous
   release; each has evidence-backed acceptance verification in its PR and
   delivery-log entry. Issues closed only after Principal QA confirmed ACs
   against merged code.
2. **Full quality gate on dev tip** — `GATE_FULL=1 scripts/quality-gate.sh`
   green (`GATE_FULL=1` adds a full-tree secret scan over every tracked file,
   not just the release diff); paste summary in the release PR.
3. **Suite status review** — every suite in
   [TEST-STRATEGY](./TEST-STRATEGY.md) §4 that maps to delivered scope is
   `tested`, with evidence linked; no obligation silently downgraded.
4. **Migrations** — applied cleanly in staging rehearsal; rollback posture
   reviewed per migration (gate G7).
5. **Backup/restore posture** — confirmed for the data this release creates.
   **Standing rule (T-13):** until issue #31 delivers a restoration drill, a
   release that introduces persistent customer/financial data is a **release
   blocker** — docs-only and ephemeral-sandbox releases are exempt.
6. **Threat register** — [THREAT-REGISTER](./THREAT-REGISTER.md) reviewed;
   no new surfaces without rows; no `accepted` statuses granted in this PR
   (product-owner decision, recorded separately).
7. **Secrets & config** — `.env.example` is current for every new variable;
   no real credentials anywhere; secret-store entries listed for operators.
8. **Rollback plan stated** in the release PR body (see policy below).
9. **Delivery log** — release entry appended to
   [DELIVERY-LOG](../DELIVERY-LOG.md) with the QA verdict.
10. **Verdict recorded** — one of:
    - `APPROVE — release to main` (all above checked, evidence linked)
    - `BLOCK — <reason>` (unmet item; the PR does not merge)

## Rollback / forward-fix policy

- **Default: revert.** Revert the release merge commit on `main` (history
  preserved; precedent PR #38 rollback note). Redeploy previous known-good
  state.
- **Forward-fix** is preferred only when a revert would itself corrupt state
  (e.g., an already-applied data migration) — in that case the fix PR must
  include a compensating migration or guarded repair command, reviewed like
  any money-touching change.
- If production data could have been exposed or mutated (T-03/T-05/T-06):
  treat as **P0 incident** — stop releases, rotate credentials, record the
  incident in `docs/DELIVERY-LOG.md` per CONTRIBUTING rule 5, notify affected
  workspace owners.
- Branch protection found disabled = P0 incident per
  [BRANCH-GOVERNANCE](../BRANCH-GOVERNANCE.md) enforcement reality check:
  stop merges, restore protection, record.

## Release PR body must contain

- Inventory of issues + merged PRs included
- Full gate output (dev tip, full-tree scan)
- Suite-status table (delivered scope)
- Rollback plan
- Backup/restore posture statement (or blocker acknowledgment)
- QA verdict with reviewer identity and date
