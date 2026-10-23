# Summary

<!-- One line: what does this PR do? -->

# Linked issue

<!-- Exactly one issue per PR. Use "Refs #N" — issue closes manually after
     Principal QA verification (auto-close keywords only fire on default-branch
     merges; our PRs target dev). -->

Refs #

# Scope

<!-- What is included in this change? What is explicitly excluded? -->

# Changes

<!-- Bullet list of concrete changes: code, migrations, docs, config. -->

# Tests & evidence

<!-- Record the local quality gate commands you ran and their outcome
     (see docs/BRANCH-GOVERNANCE.md). Paste key output, do not summarize as
     "tests pass" without evidence. Include failure/denial cases tested, not
     only the happy path. -->

```
$ <command>
<output>
```

# Risks & mitigations

<!-- Data/migration risks, authorization surface, financial invariants touched,
     rollback/forward-fix plan. -->

# Rollout notes

<!-- Deployment order, config/env changes required, backfill needs, docs to
     update at release time. -->

# Reviewer checklist (independent Staff Engineer)

- [ ] Scope matches the linked issue; nothing unrelated bundled in.
- [ ] Acceptance criteria genuinely satisfied (challenged, not assumed).
- [ ] Failure, retry, denial, and isolation cases covered by tests/evidence.
- [ ] No secrets, no unreviewed migrations, no architecture drift.
- [ ] Docs updated; delivery log entry appended.

# Principal QA (acceptance)

- [ ] Behavior verified end-to-end against the issue.
- [ ] Evidence reviewed; release verdict recorded in docs/DELIVERY-LOG.md.
