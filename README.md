<p align="center">
  <a href="https://mavka.ai/">
    <img src="assets/mavka-ai-logo.svg" alt="Mavka AI" width="220">
  </a>
</p>

<h1 align="center">Unit Test Skills by Mavka</h1>

<p align="center">
  <strong>Don’t just ask your AI agent to write tests. Give it a testing process.</strong>
</p>

<p align="center">
  These skills make your agent plan coverage first, generate focused Java unit tests,<br>
  compile them, and run them before it reports done.
</p>

<p align="center">
  <strong>Plan → Generate → Compile → Run</strong>
</p>

<p align="center">
  <code>Java</code> · <code>JUnit 5</code> · <code>Mockito</code> · <code>AssertJ</code>
</p>

<p align="center">
  <a href="https://github.com/mavka-ai/unit-tests-skills/stargazers"><img src="https://img.shields.io/github/stars/mavka-ai/unit-tests-skills?style=flat-square&amp;color=111111&amp;label=stars" alt="GitHub stars"></a>
  <a href=".claude-plugin/plugin.json"><img src="https://img.shields.io/badge/plugin-2026.9.15-111111?style=flat-square" alt="Plugin version 2026.9.15"></a>
  <a href="#supported-languages"><img src="https://img.shields.io/badge/Java-JUnit%205-111111?style=flat-square" alt="Java and JUnit 5"></a>
  <a href="#installation"><img src="https://img.shields.io/badge/agents-Claude%20Code%20%7C%20Codex-111111?style=flat-square" alt="Works with Claude Code and Codex"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/mavka-ai/unit-tests-skills?style=flat-square&amp;color=111111&amp;label=license" alt="MIT license"></a>
</p>

<p align="center">
  <strong>~42% → ~83–92% mutation score · 100% branch coverage</strong><br>
  <sub>One pinned Spring Petclinic target · 12 injected defects · Claude Code 2.1.276 / OPUS-5 · Codex 0.155.1 / gpt-5.6-sol</sub>
</p>

<p align="center">
  <a href="#installation"><strong>Install the skills ↓</strong></a>
</p>

## Why

An agent asked to "write tests" can stop as soon as the build is green. But a
green suite with full branch coverage can still miss real defects: the
benchmark below shows exactly that.

These skills give the agent a testing process instead of a one-shot prompt:
plan the cases from the code's branches, generate focused tests, compile them,
and run them before reporting done. Use them when you:

- add unit tests to an untested Java service or controller;
- want to review the planned test cases before any test code is written;
- want generated tests that follow consistent naming and structure rules.

## See the difference

**Same green build. Same 100% branch coverage. More defects detected.**

In one controlled benchmark, Claude and Codex each generated tests for the same
pinned Spring Petclinic target, first without the skill and then with it. We ran
all four suites against the original code and the same 12 deliberately
introduced defects.

**Engines:** Claude Code `2.1.276` with `OPUS-5` · Codex `0.155.1` with
`gpt-5.6-sol`

| Engine | Setup | Build | Tests | Mutants killed | Survived |
|--------|-------|-------|------:|----------------:|---------:|
| Claude | Without skill | PASS | 20 | 5 / 12 | 7 |
| Claude | With skill | PASS | 35 | 10 / 12 | 2 |
| Codex | Without skill | PASS | 15 | 5 / 12 | 7 |
| Codex | With skill | PASS | 26 | 11 / 12 | 1 |

All four suites built successfully and reported 100% branch coverage. Mutation
testing revealed the difference: the suites generated with the skill detected
10–11 of the 12 injected defects instead of 5.

<details>
<summary><strong>What is a mutant?</strong></summary>

A mutant is one deliberate, single-line change introduced into production code
after the tests are written. The suite is then run against that changed code.

- If the suite fails, the mutant is killed.
- If the suite still passes, the mutant survived.

</details>

> **Benchmark scope:** One fixed scenario on a pinned Spring Petclinic target.
> Results may vary across codebases, tasks, models, and runs.

## Installation

### Option 1: Using npx skills (Recommended)

For reliable automatic skill discovery, complete both steps:

1. Install the skills:

```bash
npx skills add mavka-ai/unit-tests-skills
```

2. Add the [`AGENTS.md` snippet](templates/AGENTS-SNIPPET.md) to your project's `AGENTS.md` file so AI agents know when and how to use the installed skills.

Or install specific skills:

```bash
npx skills add mavka-ai/unit-tests-skills --skill generate-test-cases
npx skills add mavka-ai/unit-tests-skills --skill generate-tests
```

### Option 2: Using openskills (Recommended for other agents)

[openskills](https://github.com/numman-ali/openskills) automatically generates `AGENTS.md` for maximum AI agent effectiveness.

```bash
# Install skills
npx openskills install mavka-ai/unit-tests-skills

# Auto-generate/update AGENTS.md with installed skills
npx openskills sync
```

**Why openskills?** According to [Vercel's research](https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals), skills alone trigger only 53% of the time. With `AGENTS.md`, success rate jumps to **100%**.

### Option 3: Claude Code plugin (Recommended for Claude Code)

```
/plugin marketplace add mavka-ai/unit-tests-skills
/plugin install unit-tests-skills@mavka
```

Skills are namespaced by the plugin, so they are invoked as
`/unit-tests-skills:generate-tests` and `/unit-tests-skills:generate-test-cases`.
See [Updating and Uninstalling](#updating-and-uninstalling) to keep the
installed plugin current or remove it.

## Try it

> Examples below use the plain command form. If you installed as a plugin,
> prefix the skill name with the plugin: `/unit-tests-skills:generate-tests`.

Generate tests for a class:

```
/generate-tests src/services/OrderService.java
```

Only plan the test cases, without generating code:

```
/generate-test-cases src/services/OrderService.java
```

### What you get

#### Test Cases
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

#### Generated Test
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

## How it works

`/generate-tests` runs the full workflow unattended:

1. **Plan**: analyzes the source code and prints a structured list of test cases
2. **Generate**: writes the test files from that plan
3. **Compile**: verifies the tests compile
4. **Run**: runs the tests and reports the result

### Available skills

| Skill | Command | Plugin command | Description |
|-------|---------|----------------|-------------|
| Generate Tests | `/generate-tests <target>` | `/unit-tests-skills:generate-tests <target>` | Full workflow, unattended: analyzes code, prints the test case list, generates test code, verifies it compiles and passes. Supports Java (JUnit 5, Mockito, AssertJ). |
| Generate Test Cases | `/generate-test-cases <target>` | `/unit-tests-skills:generate-test-cases <target>` | Analysis only: outputs a structured list of test cases in Given-When-Then format without generating code. |

Claude Code namespaces plugin skills by plugin name, so the command depends on
how you installed. Use the **Plugin command** after
[Option 3](#option-3-claude-code-plugin-recommended-for-claude-code); use the
plain **Command** after openskills or `npx skills`.

### Testing Principles

These skills enforce proven testing practices:

#### General Rules (All Languages)

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

### Test Case Generation Strategy

#### INCLUDE
- Each distinct code branch and outcome
- Each unique return value or exception
- Separate cases for HTTP 400, 401, 403 (never merge)
- Each independent validation failure, nearest valid and invalid values at every boundary, and at least one all-valid input case (which may be a positive boundary case)
- All paths through private methods (via public API)

#### EXCLUDE
- Redundant input variations that add no distinct behavior, condition, or boundary coverage
- Collection size variations (1, 2, 3 items) unless code has explicit size logic
- Speculative cases (exotic Unicode, massive payloads) unless explicitly handled
- Null arguments unless parameter is `@Nullable`

## Supported agents

- **Claude Code**: install as a plugin ([Option 3](#option-3-claude-code-plugin-recommended-for-claude-code)) or with `npx skills`.
- **Codex and other agents that read `AGENTS.md`**: install with `npx skills` or openskills, and make sure your `AGENTS.md` references the skills.

### Why AGENTS.md Matters

| Configuration | Success Rate |
|---------------|--------------|
| Skills alone | 53% |
| Skills + prompting | 79% |
| **AGENTS.md** | **100%** |

`AGENTS.md` provides persistent context to AI agents on every turn, without requiring them to decide to load skills first. See the [full article](https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals) for details.

## Supported languages

### Java

- JUnit 5 + Mockito + AssertJ
- `@ExtendWith(MockitoExtension.class)` for unit tests
- **FORBIDDEN:** `@SpringBootTest` in unit tests
- Use `ArgumentCaptor` instead of `any()` for DTOs
- Explicit JSON literals (no `objectMapper.writeValueAsString()`)
- `OutputCaptureExtension` for log verification

## Updating and Uninstalling

Use the commands for the installation method you originally chose.

### npx skills

Update both skills to their latest versions:

```bash
npx skills update generate-test-cases generate-tests
```

Remove both skills:

```bash
npx skills remove generate-test-cases generate-tests
```

Because the `AGENTS.md` snippet for this installation method is added manually,
remove that snippet manually after uninstalling the skills.

### openskills

Update installed skills from their recorded sources, then regenerate
`AGENTS.md`:

```bash
npx openskills update
npx openskills sync
```

Remove both skills, then regenerate `AGENTS.md` so it no longer references
them:

```bash
npx openskills remove generate-test-cases
npx openskills remove generate-tests
npx openskills sync
```

### Claude Code plugin

Refresh the marketplace listing, then update the installed plugin:

```text
/plugin marketplace update mavka
/plugin update unit-tests-skills@mavka
```

Remove the installed plugin:

```text
/plugin uninstall unit-tests-skills@mavka
```

If you no longer use anything from the `mavka` marketplace, you can also remove
the marketplace itself with `/plugin marketplace remove mavka`. Removing a
marketplace also uninstalls plugins installed from it.

## Documentation

- [Google's unit test best practices](docs/google-unit-test-best-practices.md) —
  source review and implementation status for the rules in this repository.
- [The Complete Guide to Building Skills for Claude](https://resources.anthropic.com/hubfs/The-Complete-Guide-to-Building-Skill-for-Claude.pdf)

## Contributing

Contributions are welcome via Pull Requests. All PRs require review and approval from maintainers before merging.

When adding new rules:

1. Place general rules in `skills/{skill-name}/rules/general/` (or `rules/tests/general/` for generate-tests)
2. Place language-specific rules in `skills/generate-tests/rules/tests/{language}/unit/`
3. Update skill files if new rules need explicit reference
4. Ensure your changes follow the existing format and style

### Project Structure

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

### Repository Protection

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

## Built by Mavka AI

Unit Test Skills is built by [Mavka AI](https://mavka.ai/), where we create the best AI tools and skills for developers. We’re a digital engineering company that helps growing tech businesses remove architectural debt, modernize systems, and put AI to work in everyday engineering.

**[Work with Mavka AI →](https://mavka.ai/)**
