# Optional AGENTS.md Snippet for Unit Test Skills

Agents with native skill discovery can read the installed skills directly.
Use these entries if you want explicit routing in your project's `AGENTS.md`.
Copy **only the entries for skills you installed** into your existing file.

The paths below assume a project install. For a global install, replace
`.agents/skills/` with the actual absolute path to `~/.agents/skills/`.
For Claude Code plugin installs, use the plugin's namespaced skill commands
instead of these filesystem paths.

## Generate Tests

```markdown
## Unit test generation

When asked to generate or write unit tests, read
`.agents/skills/generate-tests/SKILL.md` and follow its workflow. Resolve its
rule paths from that skill directory. It includes analysis, test-case review,
test generation, and verification; no other skill is required.
```

## Generate Test Cases

```markdown
## Test coverage analysis

When asked to list test cases or analyze test coverage without writing code,
read `.agents/skills/generate-test-cases/SKILL.md` and follow its workflow.
Resolve its rule paths from that skill directory. Output the cases in
conversation without creating or modifying files; no other skill is required.
```
