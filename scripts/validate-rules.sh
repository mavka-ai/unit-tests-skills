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

# Documents that point an agent at a rule file.
docs_for() { ls "$1/SKILL.md" "$1/rules/RULES-INDEX.md" 2>/dev/null; }

# --- 1. Every referenced rule file exists ------------------------------------
# References appear in three shapes across the skills, all of them valid:
#   ./rules/general/x.md   (from the skill root)
#   general/x.md           (from rules/tests/)
#   x.md                   (bare, in prose: "see compilation-verification.md")
# A reference resolves if any shape lands on a real file, so try each.
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
    done < <(grep -o '`[^`]*\.md`' "${doc}" | tr -d '`' | grep -v '^RULES-INDEX\.md$' | sort -u)
  done
done

# --- 2. No rule file is left unreferenced -----------------------------------
# The reverse direction of check 1. A rule added to the tree but never named in
# SKILL.md is dead weight: the agent has no instruction to read it.
echo "==> Every rule file is referenced"
for skill in skills/*/; do
  skill="${skill%/}"
  [ -d "${skill}/rules" ] || continue
  refs="$(cat $(docs_for "${skill}") 2>/dev/null || true)"
  while IFS= read -r rule; do
    case "${refs}" in
      *"$(basename "${rule}")"*) ;;
      *) fail "✘ no SKILL.md or RULES-INDEX.md references ${rule}" ;;
    esac
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
