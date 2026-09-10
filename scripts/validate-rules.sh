#!/usr/bin/env bash
#
# Validates the rule files that back each skill.
#
# A skill is only as good as the rules it actually loads. Every failure below is
# silent at runtime: the agent reads SKILL.md, follows a reference to a rule that
# is not there, and generates tests without it. Nothing errors, the output just
# gets worse. These checks make that visible at review time instead.
#
# Usage: ./scripts/validate-rules.sh
# Requires: bash, diff, find, grep. No credentials, no network.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

FAILURES="$(mktemp)"
trap 'rm -f "${FAILURES}"' EXIT

fail() { printf '%s\n' "$*" >>"${FAILURES}"; }

# Documents that point an agent at a rule file. Prints only the ones that exist,
# one per line, and always succeeds: `ls` with a missing operand exits non-zero,
# which made every caller depend on where `set -e` does and does not look.
docs_for() {
  [ -f "$1/SKILL.md" ] && printf '%s\n' "$1/SKILL.md"
  [ -f "$1/rules/RULES-INDEX.md" ] && printf '%s\n' "$1/rules/RULES-INDEX.md"
  return 0
}

# Documents that are not rules. A SKILL.md may legitimately point at AGENTS.md
# or README.md, and counting that as a rule reference turns a cross-reference
# into a build failure.
NOT_A_RULE='(^|/)(AGENTS|AGENTS-SNIPPET|CLAUDE|README|RULES-INDEX|HELP)\.md$'

# Rule references in a document, one per line, paths kept as written.
#
# Both checks below read this, so they cannot disagree on what a reference is.
# They used to: check 1 looked only at backticked tokens while check 2 matched
# the raw document text, so a bare prose mention counted as a reference for one
# and was invisible to the other. Backticks are a typographic choice, not a
# reference, so neither form is privileged here.
refs_in() {
  grep -oE '[A-Za-z0-9._/-]+\.md' "$1" \
    | sed 's|^\./||' \
    | grep -vE "${NOT_A_RULE}" \
    | sort -u \
    || true
}

# --- 1. Every referenced rule file exists ------------------------------------
# References appear in three shapes across the skills, all of them valid:
#   ./rules/general/x.md   (from the skill root)
#   general/x.md           (from rules/tests/)
#   x.md                   (bare, in prose: "see compilation-verification.md")
# A reference resolves if any shape lands on a real file, so try each. The path
# is checked as written: flattening it to a basename would let a reference name
# the wrong directory and still pass.
echo "==> Referenced rule files exist"
for skill in skills/*/; do
  skill="${skill%/}"
  for doc in $(docs_for "${skill}"); do
    while IFS= read -r ref; do
      [ -n "${ref}" ] || continue
      rel="${ref#./}"
      if [ -f "${skill}/${rel}" ] \
        || [ -f "${skill}/rules/${rel}" ] \
        || [ -f "${skill}/rules/tests/${rel}" ]; then
        continue
      fi
      # A bare basename may live anywhere under this skill's rules/.
      case "${rel}" in
        */*) ;;
        *) [ -n "$(find "${skill}/rules" -name "${rel}" -print -quit 2>/dev/null)" ] && continue ;;
      esac
      fail "✘ ${doc} references a rule that does not exist: ${ref}"
    done < <(refs_in "${doc}")
  done
done

# --- 2. No rule file is left unreferenced -----------------------------------
# The reverse direction of check 1. A rule added to the tree but never named in
# SKILL.md is dead weight: the agent has no instruction to read it.
echo "==> Every rule file is referenced"
for skill in skills/*/; do
  skill="${skill%/}"
  [ -d "${skill}/rules" ] || continue
  # Compare on basenames: check 1 owns whether a reference resolves to the right
  # path, this one only asks whether the file is named at all.
  refs="$(for doc in $(docs_for "${skill}"); do refs_in "${doc}"; done | sed 's|.*/||' | sort -u)"
  while IFS= read -r rule; do
    # Exact whole-line match. A substring test passed any rule whose basename
    # was contained in another reference — principles.md inside
    # general-principles.md — which is the silence this check exists to end.
    printf '%s\n' "${refs}" | grep -qxF "$(basename "${rule}")" \
      || fail "✘ no SKILL.md or RULES-INDEX.md references ${rule}"
  done < <(find "${skill}/rules" -name '*.md' ! -name 'RULES-INDEX.md' | sort)
done

# --- 3. General rules stay identical across skills --------------------------
# Both skills carry their own copy of the general rules, because each skill is
# installed standalone and has to be self-contained. Two copies means they can
# drift, and a drifted copy means the same request gets different rules
# depending on which skill the agent picked.
echo "==> General rules are in sync between skills"
GEN_A="skills/generate-tests/rules/tests/general"
GEN_B="skills/generate-test-cases/rules/general"
if [ -d "${GEN_A}" ] && [ -d "${GEN_B}" ]; then
  if ! diff -r "${GEN_A}" "${GEN_B}" >/dev/null 2>&1; then
    fail "✘ general rules differ between the two skills:"
    while IFS= read -r line; do fail "    ${line}"; done \
      < <(diff -rq "${GEN_A}" "${GEN_B}" 2>&1 || true)
  fi
else
  fail "✘ expected general rules in ${GEN_A} and ${GEN_B}"
fi

# --- 4. Rule files sit in a known category ----------------------------------
# This distribution ships unit-test rules only. Listing the categories that
# belong here, rather than the ones that do not, also catches a category nobody
# has invented yet.
echo "==> Rule files sit in a known category"
ALLOWED_CATEGORIES='^(general|java/unit|post-generation)/[^/]+\.md$'
while IFS= read -r rule; do
  rel="${rule#*/rules/}"
  rel="${rel#tests/}"
  printf '%s\n' "${rel}" | grep -qE "${ALLOWED_CATEGORIES}" \
    || fail "✘ rule is outside this distribution's categories: ${rule}"
done < <(find skills -path '*/rules/*' -name '*.md' ! -name 'RULES-INDEX.md' | sort)

# --- Report ------------------------------------------------------------------
echo
if [ -s "${FAILURES}" ]; then
  cat "${FAILURES}"
  echo
  echo "✘ Rule validation failed"
  exit 1
fi
echo "✔ All rule validation passed"
