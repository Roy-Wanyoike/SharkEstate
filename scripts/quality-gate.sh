#!/usr/bin/env bash
#
# SharkEstate local quality gate — normative executor (issue #14).
#
# Policy: docs/BRANCH-GOVERNANCE.md (release gate steps)
# Tests:  docs/quality/TEST-STRATEGY.md (named suites & traceability)
#
# Usage:
#   scripts/quality-gate.sh              # diff-based secret scan vs origin/dev when available
#   GATE_BASE=main scripts/quality-gate.sh   # diff against another ref
#
# Every gate reports PASS / FAIL / SKIP(reason). Any FAIL exits 1.
# Gates auto-activate as workstreams land; SKIP is loud, never silent.
#
set -u
cd "$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "not inside a git repository"; exit 1; }

PASS=0; FAIL=0; SKIP=0
FAILED_GATES=""

report() { # $1=id  $2=PASS|FAIL|SKIP  $3=detail
  printf '[%s] %-5s %s\n' "$1" "$2" "$3"
  case "$2" in
    PASS) PASS=$((PASS+1)) ;;
    FAIL) FAIL=$((FAIL+1)); FAILED_GATES="$FAILED_GATES $1" ;;
    SKIP) SKIP=$((SKIP+1)) ;;
  esac
}

# --- header -----------------------------------------------------------------
HEAD_SHA="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
BASE="${GATE_BASE:-}"
if [ -z "$BASE" ]; then
  if git rev-parse --verify --quiet origin/dev >/dev/null; then
    BASE=origin/dev
  fi
fi
echo "SharkEstate quality gate — branch=$BRANCH head=$HEAD_SHA base=${BASE:-<none> (full-tree scan)}"
echo

# --- G1: no GitHub Actions workflow files (repository constraint) -----------
# Checks tracked AND on-disk so untracked workflow files cannot slip through
# a pre-commit gate run.
wf_hits="$(git ls-files -- '.github/workflows/*'; ls -A .github/workflows 2>/dev/null | sed 's|^|.github/workflows/|')"
if [ -n "$wf_hits" ]; then
  report G1 FAIL "GitHub Actions workflow files present: $(printf '%s\n' "$wf_hits" | sort -u | tr '\n' ' ')"
else
  report G1 PASS "no GitHub Actions workflow files (tracked or on disk)"
fi

# --- G2: no committed env files + value-based secret scan -------------------
env_hits="$(git ls-files -- '.env' '.env.*' | grep -vx '.env.example' | tr '\n' ' ')"
# `.env.example` is the only allowed tracked env file; any other .env* must
# never be committed (policy: CONTRIBUTING.md rule 5).
if [ -n "$env_hits" ]; then
  report G2a FAIL "tracked env file(s) besides .env.example: $env_hits"
else
  report G2a PASS "no .env files tracked besides .env.example"
fi

SECRET_PATTERN='(password|secret|token|api[_-]?key)["'"'"' ]*[:=]["'"'"' ]*[A-Za-z0-9+/_-]{12,}'
secret_hits=""
scanned_list=""
full_scan=0
case "${GATE_FULL:-}" in 1|true|yes) full_scan=1 ;; esac
if [ -n "$BASE" ] && [ "$HEAD_SHA" != "unknown" ] && [ "$full_scan" -eq 0 ]; then
  scanned_list="$scanned_list committed-diff(${BASE}..HEAD)"
  committed="$(git diff --unified=0 "${BASE}..HEAD" -- 2>/dev/null | grep -inE "$SECRET_PATTERN" | grep -vE '^(\+\+\+|---)' || true)"
  [ -n "$committed" ] && secret_hits="$secret_hits$committed"
else
  scanned_list="$scanned_list full-tracked-tree"
fi
scanned_list="$scanned_list pending-changes(staged+unstaged)"
pending="$(git diff --unified=0 HEAD -- 2>/dev/null | grep -inE "$SECRET_PATTERN" | grep -vE '^(\+\+\+|---)' || true)"
[ -n "$pending" ] && secret_hits="$secret_hits$pending"
untracked_files="$(git ls-files --others --exclude-standard)"
if [ -n "$untracked_files" ]; then
  scanned_list="$scanned_list untracked-files"
  # GNU xargs assumed (-r); documented dev environment is Linux (docs/local-development.md)
  untracked="$(printf '%s\n' "$untracked_files" | tr '\n' '\0' | xargs -0 -r grep -HnE "$SECRET_PATTERN" 2>/dev/null || true)"
  [ -n "$untracked" ] && secret_hits="$secret_hits$untracked"
fi
if [ -n "$secret_hits" ]; then
  report G2b FAIL "credential-like assignments found (scanned:$scanned_list)"
  printf '%s\n' "$secret_hits" | sed 's/^/       /'
else
  report G2b PASS "secret scan clean (scanned:$scanned_list)"
fi

# --- G3: relative markdown links resolve ------------------------------------
link_failures=""
while IFS= read -r f; do
  dir="$(dirname "$f")"
  targets="$(grep -oE '\]\([^)]+\)' "$f" 2>/dev/null | sed -E 's/^\]\(//; s/\)$//')"
  while IFS= read -r t; do
    [ -z "$t" ] && continue
    case "$t" in
      \#*|http://*|https://*|mailto:*) continue ;;
      *"://"*) continue ;;
    esac
    t="${t%%\"*}"                 # strip markdown link title if present
    path="${t%%#*}"
    [ -z "$path" ] && continue
    path="${path//%20/ }"
    if [ ! -e "$dir/$path" ]; then
      link_failures="$link_failures\n         $f -> $t"
    fi
  done <<< "$targets"
done < <(git ls-files -- '*.md')
if [ -n "$link_failures" ]; then
  report G3 FAIL "unresolvable relative markdown links:"
  printf '%b\n' "$link_failures"
else
  report G3 PASS "all relative markdown links resolve"
fi

# --- G4: Go backend workstream (activates with issue #4) --------------------
if git ls-files -- 'go.mod' '*.go' | grep -q .; then
  if command -v go >/dev/null 2>&1; then
    unformatted="$(gofmt -l . 2>/dev/null | tr '\n' ' ')"
    if [ -z "$unformatted" ]; then
      report G4a PASS "gofmt clean"
    else
      report G4a FAIL "gofmt needs formatting: $unformatted"
    fi
    if go vet ./... >/dev/null 2>&1; then
      report G4b PASS "go vet"
    else
      report G4b FAIL "go vet reported problems"
    fi
    if go test ./... >/dev/null 2>&1; then
      report G4c PASS "go test ./..."
    else
      report G4c FAIL "go test ./... failed"
    fi
  else
    report G4 FAIL "Go code present but the go toolchain is not installed"
  fi
else
  report G4 SKIP "backend not scaffolded yet (lands with issue #4)"
fi

# --- G5: frontend workstream (activates with the web/ scaffold) -------------
if [ -f web/package.json ]; then
  if command -v bun >/dev/null 2>&1; then
    if (cd web && bun install --frozen-lockfile >/dev/null 2>&1); then
      report G5a PASS "bun install --frozen-lockfile"
    else
      report G5a FAIL "bun install failed (lockfile drift or registry error)"
    fi
    if node -e 'const p=require("./web/package.json");process.exit(p.scripts&&p.scripts.lint?0:1)' 2>/dev/null; then
      if (cd web && bun run lint >/dev/null 2>&1); then
        report G5b PASS "bun run lint"
      else
        report G5b FAIL "bun run lint"
      fi
    else
      report G5b SKIP "no lint script defined in web/package.json"
    fi
    if node -e 'const p=require("./web/package.json");process.exit(p.scripts&&p.scripts.build?0:1)' 2>/dev/null; then
      if (cd web && bun run build >/dev/null 2>&1); then
        report G5c PASS "bun run build"
      else
        report G5c FAIL "bun run build"
      fi
    else
      report G5c SKIP "no build script defined in web/package.json"
    fi
    if git ls-files -- 'web/*.test.*' 'web/**/*.test.*' | grep -q . || node -e 'const p=require("./web/package.json");process.exit(p.scripts&&p.scripts.test?0:1)' 2>/dev/null; then
      if (cd web && bun test >/dev/null 2>&1 || (cd web && bun run test >/dev/null 2>&1)); then
        report G5d PASS "bun test"
      else
        report G5d FAIL "frontend tests failed"
      fi
    else
      report G5d SKIP "no frontend tests present yet"
    fi
  else
    report G5 FAIL "web/ present but bun is not installed"
  fi
else
  report G5 SKIP "frontend not scaffolded yet (lands with the identity/UX workstreams)"
fi

# --- G6: dependency vulnerability scanning (local tooling, no Actions) ------
if git ls-files -- 'go.mod' | grep -q .; then
  if command -v govulncheck >/dev/null 2>&1; then
    if govulncheck ./... >/dev/null 2>&1; then
      report G6a PASS "govulncheck: no known vulnerabilities"
    else
      report G6a FAIL "govulncheck reported vulnerabilities"
    fi
  else
    report G6a SKIP "govulncheck not installed (install: go install golang.org/x/vuln/cmd/govulncheck@latest)"
  fi
else
  report G6a SKIP "no Go module yet (govulncheck activates with issue #4)"
fi
if [ -f web/package.json ]; then
  audit_out="$(cd web && bun audit 2>&1)"
  audit_rc=$?
  if [ $audit_rc -eq 0 ]; then
    report G6b PASS "bun audit: no known vulnerabilities"
  elif printf '%s' "$audit_out" | grep -qiE 'ENOTFOUND|ECONNREFUSED|network|ETIMEDOUT|fetch failed'; then
    report G6b SKIP "bun audit unreachable (offline?) — rerun with network access before release"
  else
    report G6b FAIL "bun audit reported vulnerabilities"
  fi
else
  report G6b SKIP "frontend not scaffolded yet"
fi

# --- G7: migrations carry a rollback posture (activates with issue #4) ------
migrations="$(git ls-files -- '*.up.sql')"
if [ -z "$migrations" ]; then
  report G7 SKIP "no schema migrations yet (activates with issue #4)"
else
  missing_posture=""
  for u in $migrations; do
    down="${u%.up.sql}.down.sql"
    if git cat-file -e "HEAD:$down" 2>/dev/null; then
      continue
    fi
    if ! grep -qi "ROLLBACK POSTURE" "$u" 2>/dev/null; then
      missing_posture="$missing_posture $u"
    fi
  done
  if [ -z "$missing_posture" ]; then
    report G7 PASS "every migration has a .down.sql or an in-file ROLLBACK POSTURE note"
  else
    report G7 FAIL "migrations without rollback posture:$missing_posture"
  fi
fi

# --- summary ----------------------------------------------------------------
echo
printf 'Summary: %d pass, %d fail, %d skip\n' "$PASS" "$FAIL" "$SKIP"
if [ "$FAIL" -gt 0 ]; then
  echo "QUALITY GATE: FAILED — failing gates:$FAILED_GATES"
  echo "A PR without a green gate is not reviewable (docs/BRANCH-GOVERNANCE.md)."
  exit 1
fi
echo "QUALITY GATE: PASSED"
exit 0
