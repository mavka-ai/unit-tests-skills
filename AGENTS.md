# AGENTS.md

Guidance for AI agents working with this repository.

## Overview

Skills for generating unit tests with consistent quality. Each skill is self-contained.

## Skills

| Command                       | What it does                          |
|-------------------------------|---------------------------------------|
| `/generate-tests <file>`      | Full workflow: analyzes code, outputs test cases for review, generates test code |
| `/generate-test-cases <file>` | Analysis only: outputs test case list without generating code |

## Rules Location

Rules are inside each skill folder:

- `generate-test-cases/rules/general/` — general rules only
- `generate-tests/rules/tests/` — all rules (general, java, post-generation)

## Plugin Validation

This repository doubles as a Claude Code plugin **and** a marketplace, declared
in `.claude-plugin/`. Both manifests must stay valid, because the
community-marketplace review pipeline runs `claude plugin validate` on every
submission.

**After changing anything under `.claude-plugin/` or `skills/`, run:**

```bash
./scripts/validate-plugin.sh
```

CI runs the same script on every pull request touching those paths
(`.github/workflows/validate-plugin.yml`). No credentials are needed —
validation is entirely local.

### What it checks, and why each check exists

| Check | Why it is not redundant |
|---|---|
| `claude plugin validate . --strict` | Validates the marketplace manifest. `--strict` promotes warnings to errors, which matters because the CLI reports a `version` that disagrees between the entry and `plugin.json` as a *warning* — while `plugin.json` silently wins at install time. |
| `claude plugin validate <copy> --strict` | The validator switches to marketplace mode the moment it sees `marketplace.json`, so validating the repo root **never** exercises `plugin.json`'s own schema. The script copies the plugin without the marketplace file to force plugin mode. |
| Entry name matches `plugin.json` | The CLI does **not** check this. A marketplace entry naming a plugin that `plugin.json` does not define validates cleanly and only fails later at install time with `Plugin "<name>" not found in marketplace`. Verified against claude 2.1.235. |

### Conventions that follow from this

- Declare `version` in `plugin.json` **only**. Repeating it in the marketplace
  entry adds a way for the two to drift, and the entry's copy is ignored.
- The plugin `name` is immutable once published — it is the install id and the
  skill namespace (`/unit-tests-skills:generate-tests`). Do not rename it.
- Keep `skills/` at the repository root. Only `plugin.json` and
  `marketplace.json` belong inside `.claude-plugin/`.

## Rule Validation

A skill is only as good as the rules it actually loads, and every way that can
break is silent at runtime: the agent reads `SKILL.md`, follows a reference to a
rule that is not there, and generates tests without it. Nothing errors — the
output just gets worse.

**After adding, renaming, moving, or deleting anything under a skill's `rules/`,
run:**

```bash
./scripts/validate-rules.sh
```

CI runs the same script in its own workflow
(`.github/workflows/validate-rules.yml`), on **every** pull request rather than
only ones touching `skills/`. Two reasons it is separate from plugin
validation: it needs no Node and no CLI, so a broken upstream release cannot
take it down; and it carries no path filter, so it always reports and is safe
to require before merge. A required check that gets skipped never reports, and
a pull request waiting on a check that will never arrive cannot merge.

### What it checks, and why each check exists

| Check | What it catches |
|---|---|
| Referenced rule files exist | A reference in `SKILL.md` (or `RULES-INDEX.md`) naming a file that is not on disk. References come in three valid shapes — `./rules/general/x.md` from the skill root, `general/x.md` from `rules/tests/`, and a bare `x.md` in prose — so a reference passes if any shape resolves. |
| Every rule file is referenced | The reverse direction. A rule added to the tree but never named in `SKILL.md` is dead weight: nothing instructs the agent to read it. |
| General rules are in sync | Each skill carries its own copy of the general rules, because a skill is installed standalone and has to be self-contained. Two copies can drift, and a drifted copy means the same request gets different rules depending on which skill the agent picked. |
| Rule files sit in a known category | This distribution ships unit-test rules only. The check lists the categories that belong here (`general/`, `java/unit/`, `post-generation/`) rather than the ones that do not, so it also catches a category nobody has invented yet. |

### Conventions that follow from this

- A new rule takes two edits, not one: the file itself **and** an entry in the
  relevant `SKILL.md`. The second check fails without it.
- Edit general rules in both locations in the same commit. Fixing one copy and
  leaving the other for later fails the third check.

## Creating a New Skill

### Directory Structure

```
skills/
  {skill-name}/
    SKILL.md
    rules/          # Rules used by this skill
```

### Naming Conventions

- **Skill directory**: `kebab-case` (e.g., `generate-tests`, `generate-test-cases`)
- **SKILL.md**: Always uppercase, exact filename

### SKILL.md Format

```markdown
---
name: skill-name
description: One sentence describing when to use this skill.
allowed-tools: Read, Write, Glob, Grep
---

# Skill Title

What this skill does.

## Rules Reference

List rule files from `./rules/` directory.

## Instructions

**Target:** $ARGUMENTS

Steps:
1. First step
2. Second step
3. ...
```

## Adding a New Rule

Add rules inside the skill folder that uses them:

```
skills/{skill-name}/rules/
  general/
    {rule-name}.md
  {language}/unit/
    {rule-name}.md
```

Then list it in that skill's `SKILL.md` and run `./scripts/validate-rules.sh`.
See [Rule Validation](#rule-validation) for what the checks enforce.

### Rule File Format

```markdown
## Rule Title

Why this rule matters.

**Incorrect:**

```java
// Bad example
```

**Correct:**

```java
// Good example
```

### Guidelines

1. Guideline one
2. Guideline two
```