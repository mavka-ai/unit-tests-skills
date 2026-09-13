<div align="center">
<br/>

<a href="https://mavka.ai/">
  <img src="assets/mavka-ai-logo.svg" alt="Mavka AI" width="320" />
</a>

### AI agent skills for generating high-quality unit tests

[Website](https://mavka.ai/)

</div>


[Mavka AI](https://mavka.ai/) is the digital engineering company behind these skills. We help growing tech businesses eliminate architectural debt and accelerate development with AI — through codebase and infrastructure audits, technical debt remediation and system modernization, and knowledge transfer to client teams — so engineering stops being your bottleneck.

> Curious how much technical debt is quietly slowing your team down? Find out at [mavka.ai](https://mavka.ai/).

## Installation

**unit-tests-skills** is a collection of AI agent skills for generating high-quality unit tests. These skills encode battle-tested testing principles that work across any programming language.

### Recommended: select skills and agents with `npx skills`

Run this **in the project where you want to use the skills**, from your own
terminal (Node.js 22.20+ and Git required):

```bash
npx skills add mavka-ai/unit-tests-skills
```

In the interactive installer:

1. Select the skills you need. **Space toggles a checkbox; Enter confirms the
   checked items. Moving the cursor does not select a skill.**
2. Select your agents. Keep **Universal (`.agents/skills`)** selected; add
   **Claude Code** if you use it. Codex and other agents that read
   `.agents/skills` share that directory.
3. Choose **Project** or **Global** scope.
4. Choose **Symlink** when offered, then check the paths and selected skills in
   the installation summary before confirming.

Agent auto-detection can skip the agent picker. To control exactly what gets
installed, pass the skill and agents explicitly:

```bash
# One skill, shared by Codex and Claude Code; scope is still prompted
npx skills add mavka-ai/unit-tests-skills --skill generate-tests --agent codex claude-code

# Analysis only, shared by Codex and Claude Code
npx skills add mavka-ai/unit-tests-skills --skill generate-test-cases --agent codex claude-code

# Claude Code with a neutral canonical directory (keep universal here)
npx skills add mavka-ai/unit-tests-skills --skill generate-tests --agent universal claude-code

# Codex only
npx skills add mavka-ai/unit-tests-skills --skill generate-tests --agent codex
```

Use `--list` to inspect the available skills without installing them. Other agent
IDs and options are listed in the [skills CLI documentation](https://github.com/vercel-labs/skills).

For a repeatable install without prompts, specify both the skill and agents:

```bash
# Project scope: canonical files under ./.agents/skills
npx skills add mavka-ai/unit-tests-skills --skill generate-tests --agent universal claude-code --yes

# Global scope: canonical files under ~/.agents/skills
npx skills add mavka-ai/unit-tests-skills --skill generate-tests --agent universal claude-code --global --yes
```

`--yes` skips all prompts; without `--skill` it installs all discovered skills.
When an AI agent runs the CLI, it may also switch to noninteractive mode, so give
it the explicit skill, agents, and scope you want.

With `universal` (or `codex`) plus `claude-code` and **Symlink**, the layout is:

```text
.agents/skills/generate-tests/          # canonical files, including all rules
.claude/skills/generate-tests          # symlink → ../../.agents/skills/generate-tests
```

The same layout lives under your home directory for global installs. Selecting
only `claude-code` makes the CLI copy directly to `.claude/skills`; include
`universal` to keep the canonical files neutral. Avoid `--copy` for the shared
layout. Agents that read `.agents/skills` can discover its contents even when
not explicitly selected; agent selection is not an access restriction.

Each skill is independently installable. `generate-tests` includes its own
analysis workflow and rules; it does not invoke or require
`generate-test-cases`. The analysis skill likewise needs no generation skill.

### Claude Code plugin: install the whole collection

Use this option if you want **both skills as a Claude Code plugin**. It uses
Claude Code's plugin storage, rather than the `.agents/skills` layout above.

```text
/plugin marketplace add mavka-ai/unit-tests-skills
/plugin install unit-tests-skills@mavka
```

Plugin commands are `/unit-tests-skills:generate-tests` and
`/unit-tests-skills:generate-test-cases`. Update with
`/plugin marketplace update mavka`. For individual skills, use `npx skills`.
Choose one installation method to avoid duplicate skill discovery.

### Moving from openskills

`openskills` controls its own selection UI and installation paths. Its default
install writes to `.claude/skills`; it does not provide the agent/scope/symlink
workflow described above. Use `npx skills` for new installs.

If you already installed these skills with openskills:

1. Review and back up any local changes in the existing skill directories.
2. Remove only the copies you are replacing: `npx openskills remove generate-tests`
   and/or `npx openskills remove generate-test-cases`. Confirm the displayed path
   matches the project or global copy you intended to remove.
3. If you used `openskills sync`, remove the corresponding stale entries from
   `AGENTS.md` or rerun `npx openskills sync` and inspect its changes.
4. Reinstall the desired skills with the commands above. For Claude Code, check
   that `.claude/skills/<skill>` is a symlink to `.agents/skills/<skill>`.

### Optional project instructions

Agents with native skill discovery can use the installed `SKILL.md` files
directly. To explicitly route unit-test requests, copy only the relevant entries
from [`templates/AGENTS-SNIPPET.md`](templates/AGENTS-SNIPPET.md) into your project's
`AGENTS.md`. The snippet is optional and must match the skills actually installed.

## Available Skills

| Skill | Command | Plugin command | Description |
|-------|---------|----------------|-------------|
| Generate Tests | `/generate-tests <target>` | `/unit-tests-skills:generate-tests <target>` | Full workflow: analyzes code, outputs test cases for review, then generates test code. Supports Java (JUnit 5, Mockito, AssertJ). |
| Generate Test Cases | `/generate-test-cases <target>` | `/unit-tests-skills:generate-test-cases <target>` | Analysis only: outputs a structured list of test cases in Given-When-Then format without generating code. |

Claude Code namespaces plugin skills by plugin name, so the command depends on
how you installed. Use the **Plugin command** after
[the plugin installation](#claude-code-plugin-install-the-whole-collection); use the
plain **Command** with agents that support slash commands after `npx skills`.
Otherwise, name the skill and target file in your request.

## Usage

> Examples below use the plain command form. If you installed as a plugin,
> prefix the skill name with the plugin: `/unit-tests-skills:generate-tests`.

### Generate Tests (Primary Skill)

```
/generate-tests src/services/OrderService.java
```

This single command handles the full workflow:
1. Analyzes the source code and outputs a structured list of test cases
2. Asks you to review the test cases before proceeding
3. Generates the actual test files
4. Verifies compilation

### Analyze Test Coverage Only

If you only want to see what test cases are needed without generating code:

```
/generate-test-cases src/services/OrderService.java
```

## Testing Principles

These skills enforce proven testing practices:

### General Rules (All Languages)

| Rule | Description |
|------|-------------|
| **Test Case Strategy** | Strict INCLUDE/EXCLUDE criteria - test each code branch, not collection sizes |
| **Naming Conventions** | `{method}_{state}_{outcome}` format for clarity |
| **Given-When-Then** | Clear structure with `actual`/`expected` prefixes |
| **Keep Tests Focused** | One scenario per test, single responsibility |
| **Test Behaviors** | Test what it does, not how it's implemented |
| **No Logic in Tests** | KISS > DRY - use literal values, avoid calculations |
| **Clean Test Data** | Use helpers and builders, never rely on defaults |
| **Cause-Effect Clarity** | Setup belongs in the test, not in distant `@BeforeEach` |
| **Public APIs First** | Test through public interfaces, not private methods |
| **Verify Relevant Args** | Use `any()` for irrelevant arguments in mocks |

### Language-Specific Rules

#### Java
- JUnit 5 + Mockito + AssertJ
- `@ExtendWith(MockitoExtension.class)` for unit tests
- **FORBIDDEN:** `@SpringBootTest` in unit tests
- Use `ArgumentCaptor` instead of `any()` for DTOs
- Explicit JSON literals (no `objectMapper.writeValueAsString()`)
- `OutputCaptureExtension` for log verification

## Project Structure

```
skills/
├── generate-test-cases/
│   ├── SKILL.md
│   └── rules/general/
└── generate-tests/
    ├── SKILL.md
    └── rules/tests/
        ├── general/
        ├── java/unit/
        └── post-generation/
```

## Test Case Generation Strategy

### INCLUDE
- Each distinct code branch and outcome
- Each unique return value or exception
- Separate cases for HTTP 400, 401, 403 (never merge)
- Negative test cases for validation constraints
- All paths through private methods (via public API)

### EXCLUDE
- Duplicate scenarios with same observable result
- Collection size variations (1, 2, 3 items) unless code has explicit size logic
- Speculative cases (exotic Unicode, massive payloads) unless explicitly handled
- Null arguments unless parameter is `@Nullable`
- Multiple tests for same exception type

## Example Output

### Test Cases
```
## Test Cases for OrderService.calculateTotal

### 1. calculateTotal_validProducts_returnsSum
- **Given:** List with products priced at 50.0 and 100.0
- **When:** calculateTotal() is called
- **Then:** Returns 150.0
- **Code branch:** Happy path

### 2. calculateTotal_emptyList_throwsIllegalArgumentException
- **Given:** Empty product list
- **When:** calculateTotal() is called
- **Then:** Throws IllegalArgumentException
- **Code branch:** Validation - empty input
```

### Generated Test
```java
@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @Mock
    private ProductRepository productRepository;

    @InjectMocks
    private OrderService orderService;

    @Test
    void calculateTotal_validProducts_returnsSum() {
        // Given
        var product1 = new Product("A", 50.0);
        var product2 = new Product("B", 100.0);
        when(productRepository.findAll()).thenReturn(List.of(product1, product2));

        // When
        double actualTotal = orderService.calculateTotal();

        // Then
        double expectedTotal = 150.0;
        assertThat(actualTotal).isEqualTo(expectedTotal);
    }
}
```

## Contributing

Contributions are welcome via Pull Requests. All PRs require review and approval from maintainers before merging.

When adding new rules:

1. Place general rules in `skills/{skill-name}/rules/general/` (or `rules/tests/general/` for generate-tests)
2. Place language-specific rules in `skills/generate-tests/rules/tests/{language}/unit/`
3. Update skill files if new rules need explicit reference
4. Ensure your changes follow the existing format and style

### Validate installation

```bash
./scripts/validate-plugin.sh
./scripts/validate-rules.sh
node --test scripts/test-installation.mjs
```

The installation smoke tests need Node.js 22.20+, Git, and npm/network access.
They install each skill separately from the collection and from an isolated
skill directory into temporary projects, checking bundled rules, skill selection,
Codex discovery paths, and Claude symlinks. No global skills are installed.
To use an already installed CLI offline, set `SKILLS_CLI` to its absolute
`bin/cli.mjs` path. CI runs these tests with the current `skills` CLI.

## Repository Protection

This repository uses branch protection rules:
- Direct pushes to `main` are disabled
- All changes require a Pull Request
- PRs require at least one approval from CODEOWNERS
- Status checks must pass before merging

## License

Released under the [MIT License](LICENSE) — free to use, modify, and embed in
commercial and closed-source projects, provided the copyright notice is retained.

## Trademark

The MIT License covers copyright only. **Mavka**® is a registered European Union
trade mark (EUTM No. 019310487) of CLEAR-SOLUTIONS sp. z o.o., which operates as
Mavka AI; **Mavka AI**™ and the Mavka AI logo are used as unregistered marks. The
marks are not licensed with the code. Referring to the project by name is fine;
using them in your own product or fork's name is not. See
[TRADEMARK.md](TRADEMARK.md) for the full policy.

## Google's unit tests best practices

> **Legend:** Implemented = rule file exists in skills | Not implemented = no rule file yet
> Priority: HIGH / MEDIUM / LOW — based on impact on unit test quality

- [Tech on the Toilet: Driving Software Excellence, One Bathroom Break at a Time](https://testing.googleblog.com/2024/12/tech-on-toilet-driving-software.html) - Dec 2024 (announcement of continuation)
- [Increase Test Fidelity By Avoiding Mocks](https://testing.googleblog.com/2024/02/increase-test-fidelity-by-avoiding-mocks.html) - Feb 2024 — **NOT IMPLEMENTED** (HIGH) — real > fake > mock hierarchy
- [Testing on the Toilet: Separation of Concerns? That's a Wrap!](https://testing.googleblog.com/2020/12/testing-on-toilet-separation-of.html) - Dec 2020 — **NOT IMPLEMENTED** (MEDIUM) — wrap third-party APIs for testability
- [Testing on the Toilet: Testing UI Logic? Follow the User!](https://testing.googleblog.com/2020/10/testing-on-toilet-testing-ui-logic.html) - Oct 2020 — **NOT IMPLEMENTED** (LOW) — UI-specific, relevant for frontend rules
- [Testing on the Toilet: Don't Mock Types You Don't Own](https://testing.googleblog.com/2020/07/testing-on-toilet-dont-mock-types-you.html) - Jul 2020 — **NOT IMPLEMENTED** (HIGH) — never mock third-party types
- [Testing on the Toilet: Tests Too DRY? Make Them DAMP!](https://testing.googleblog.com/2019/12/testing-on-toilet-tests-too-dry-make.html) - Dec 2019 — **PARTIALLY IMPLEMENTED** (LOW) — DAMP principle not explicit, covered partly by `no-logic-in-tests.md`
- [Testing on the Toilet: Exercise Service Call Contracts in Tests](https://testing.googleblog.com/2018/11/testing-on-toilet-exercise-service-call.html) - Nov 2018 — **NOT IMPLEMENTED** (MEDIUM) — prefer fakes/hermetic servers over mocking services
- [Testing on the Toilet: Only Verify Relevant Method Arguments](https://testing.googleblog.com/2018/06/testing-on-toilet-only-verify-relevant.html) - Jun 2018 — **IMPLEMENTED** — `verify-relevant-arguments-only.md`
- [Testing on the Toilet: Keep Tests Focused](https://testing.googleblog.com/2018/06/testing-on-toilet-keep-tests-focused.html) - Jun 2018 — **IMPLEMENTED** — `keep-tests-focused.md`
- [Testing on the Toilet: Cleanly Create Test Data](https://testing.googleblog.com/2018/02/testing-on-toilet-cleanly-create-test.html) - Feb 2018 — **IMPLEMENTED** — `cleanly-create-test-data.md`
- [Testing on the Toilet: Only Verify State-Changing Method Calls](https://testing.googleblog.com/2017/12/testing-on-toilet-only-verify-state.html) - Dec 2017 — **NOT IMPLEMENTED** (HIGH) — don't verify query/getter methods
- [Testing on the Toilet: Keep Cause and Effect Clear](https://testing.googleblog.com/2017/01/testing-on-toilet-keep-cause-and-effect.html) - Jan 2017 — **IMPLEMENTED** — `keep-cause-effect-clear.md`
- [Testing on the Toilet: What Makes a Good End-to-End Test?](https://testing.googleblog.com/2016/09/testing-on-toilet-what-makes-good-end.html) - Sep 2016 — **PARTIALLY IMPLEMENTED** — `what-makes-good-test.md` (CCCR framework adapted from E2E post; fidelity and precision properties are not covered)
- [Testing on the Toilet: Change-Detector Tests Considered Harmful](https://testing.googleblog.com/2015/01/testing-on-toilet-change-detector-tests.html) - Jan 2015 — **NOT IMPLEMENTED** (HIGH) — avoid tests that mirror production code
- [Testing on the Toilet: Prefer Testing Public APIs Over Implementation-Detail Classes](https://testing.googleblog.com/2015/01/testing-on-toilet-prefer-testing-public.html) - Jan 2015 — **IMPLEMENTED** — `prefer-public-apis.md`
- [Testing on the Toilet: Writing Descriptive Test Names](https://testing.googleblog.com/2014/10/testing-on-toilet-writing-descriptive.html) - Oct 2014 — **IMPLEMENTED** — `naming-conventions.md`
- [Testing on the Toilet: Don't Put Logic in Tests](https://testing.googleblog.com/2014/07/testing-on-toilet-dont-put-logic-in.html) - Jul 2014 — **IMPLEMENTED** — `no-logic-in-tests.md`
- [Testing on the Toilet: Risk-Driven Testing](https://testing.googleblog.com/2014/05/testing-on-toilet-risk-driven-testing.html) - May 2014 — **NOT IMPLEMENTED** (LOW) — risk-based test prioritization
- [Testing on the Toilet: Effective Testing](https://testing.googleblog.com/2014/05/testing-on-toilet-effective-testing.html) - May 2014 — **PARTIALLY IMPLEMENTED** (LOW) — fidelity + precision missing from CCCR framework in `what-makes-good-test.md`
- [Testing on the Toilet: Test Behaviors, Not Methods](https://testing.googleblog.com/2014/04/testing-on-toilet-test-behaviors-not.html) - Apr 2014 — **IMPLEMENTED** — `test-behaviors-not-methods.md`
- [Testing on the Toilet: Test Behavior, Not Implementation](https://testing.googleblog.com/2013/08/testing-on-toilet-test-behavior-not.html) - Aug 2013 — **IMPLEMENTED** — `test-behaviors-not-methods.md`, `general-principles.md`
- [Testing on the Toilet: Know Your Test Doubles](https://testing.googleblog.com/2013/07/testing-on-toilet-know-your-test-doubles.html) - Jul 2013 — **NOT IMPLEMENTED** (HIGH) — stub vs mock vs fake distinctions
- [Testing on the Toilet: Fake Your Way to Better Tests](https://testing.googleblog.com/2013/06/testing-on-toilet-fake-your-way-to.html) - Jun 2013 — **NOT IMPLEMENTED** (HIGH) — prefer fakes, fake at lowest layer
- [Testing on the Toilet: Don't Overuse Mocks](https://testing.googleblog.com/2013/05/testing-on-toilet-dont-overuse-mocks.html) - May 2013 — **NOT IMPLEMENTED** (HIGH) — limit to 1-2 mocks per test
- [Testing on the Toilet: Testing State vs. Testing Interactions](https://testing.googleblog.com/2013/03/testing-on-toilet-testing-state-vs.html) - Mar 2013 — **NOT IMPLEMENTED** (HIGH) — prefer state testing over verify()
- [TotT: Making a Perfect Matcher](https://testing.googleblog.com/2009/10/tott-making-perfect-matcher.html) - Oct 2009
- [TotT: Finding Data Races in C++](https://testing.googleblog.com/2008/11/tott-contain-your-environment.html) - Nov 2008
- [TotT: Contain Your Environment](https://testing.googleblog.com/2008/10/tott-contain-your-environment.html) - Oct 2008
- [TotT: Floating-Point Comparison](https://testing.googleblog.com/2008/10/tott-floating-point-comparison.html) - Oct 2008
- [TotT: Simulating Time in jsUnit Tests](https://testing.googleblog.com/2008/10/tott-simulating-time-in-jsunit-tests.html) - Oct 2008
- [TotT: Data Driven Traps!](https://testing.googleblog.com/2008/09/tott-data-driven-traps.html) - Sep 2008
- [TotT: Sleeping != Synchronization](https://testing.googleblog.com/2008/08/tott-sleeping-synchronization.html) - Aug 2008
- [TotT: 100 and counting](https://testing.googleblog.com/2008/08/tott-100-and-counting.html) - Aug 2008
- [TotT: A Matter of Black and White](https://testing.googleblog.com/2008/08/progressive-developer-knows-that-in.html) - Aug 2008
- [TotT: Testing Against Interfaces](https://testing.googleblog.com/2008/07/tott-testing-against-interfaces.html) - Jul 2008
- [TotT: EXPECT vs. ASSERT](https://testing.googleblog.com/2008/07/tott-expect-vs-assert.html) - Jul 2008
- [TotT: Defeat "Static Cling"](https://testing.googleblog.com/2008/06/defeat-static-cling.html) - Jun 2008 — **NOT IMPLEMENTED** (MEDIUM) — wrap statics behind injectable interfaces
- [TotT: Friends You Can Depend On](https://testing.googleblog.com/2008/06/tott-friends-you-can-depend-on.html) - Jun 2008
- [TotT: The Invisible Branch](https://testing.googleblog.com/2008/05/tott-invisible-branch.html) - May 2008
- [TotT: Using Dependency Injection to Avoid Singletons](https://testing.googleblog.com/2008/05/tott-using-dependancy-injection-to.html) - May 2008 — **NOT IMPLEMENTED** (MEDIUM) — constructor injection for testability
- [TotT: Testable Contracts Make Exceptional Neighbors](https://testing.googleblog.com/2008/05/tott-testable-contracts-make.html) - May 2008
- [TotT: Avoiding Flakey Tests](https://testing.googleblog.com/2008/04/tott-avoiding-flakey-tests.html) - Apr 2008 — **NOT IMPLEMENTED** (LOW) — resource isolation between tests
- [TotT: Time is Random](https://testing.googleblog.com/2008/04/tott-time-is-random.html) - Apr 2008
- [TotT: Understanding Your Coverage Data](https://testing.googleblog.com/2008/03/tott-understanding-your-coverage-data.html) - Mar 2008
- [TotT: TestNG on the Toilet](https://testing.googleblog.com/2008/03/tott-testng-on-toilet.html) - Mar 2008
- [TotT: The Stroop Effect](https://testing.googleblog.com/2008/02/tott-stroop-effect.html) - Feb 2008
- [TotT: Too Many Tests](https://testing.googleblog.com/2008/02/in-movie-amadeus-austrian-emperor.html) - Feb 2008
- [TotT: Refactoring Tests in the Red](https://testing.googleblog.com/2007/04/tott-refactoring-tests-in-red.html) - Apr 2007
- [TotT: Stubs Speed up Your Unit Tests](https://testing.googleblog.com/2007/04/tott-stubs-speed-up-your-unit-tests.html) - Apr 2007
- [TotT: Extracting Methods to Simplify Testing](https://testing.googleblog.com/2007/06/tott-extracting-methods-to-simplify.html) - Jun 2007

## Guide to Building Skills for Claude
[The Complete Guide to Building Skills for Claude](https://resources.anthropic.com/hubfs/The-Complete-Guide-to-Building-Skill-for-Claude.pdf)

