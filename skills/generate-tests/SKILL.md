---
name: generate-tests
description: "Use when the user asks to generate, create, or write unit tests for code. Analyzes the target code, produces a structured test case list for review, then generates test code. Supports Java (JUnit 5, Mockito, AssertJ)."
---

# Generate Tests Skill

You will analyze code and generate high-quality unit tests for a given target.

**Target to test:** Use the file, class, or method supplied with the skill
invocation or in the user's request. If the host substitutes `$ARGUMENTS`, use
that value. If no target is supplied, ask the user to identify it.

## Runtime and Resource Paths

This skill is self-contained: its workflow and all required rules are bundled
in this directory. No other skill or repository checkout is required.
Resolve `./rules/` paths relative to the directory containing this `SKILL.md`,
not the target project's working directory. Resolve source and test paths
against the target project.

Use your agent's available tools to read and search files, edit tests, and
run build commands. Tool names differ across agents.

## Quality Standards

- Take your time to analyze the code thoroughly before generating test cases.
- Quality is more important than speed — read all relevant source files and rules carefully.
- Do not skip any step in the workflow below. Every step exists for a reason.
- Do not take shortcuts with test data — read the actual classes to use correct constructors and fields.

---

## Instructions

### Step 1: Read Rules and Analyze Context

1. **Read the relevant rules** from `./rules/tests/` based on code type (see Rules Reference below)
2. **Read the target** source file/class/method
3. **Read dependencies**: Follow imports to read DTOs, entities, enums, custom exceptions, and other types referenced by the target (as specified in `code-context-analysis` rule)
4. **Check for existing tests**: Search for `{ClassName}Test` or `{ClassName}Tests` in the test directory (as specified in `existing-test-awareness` rule)
   - If found, read fully — you will add missing tests to it, not create a new file
   - If not found, scan 2-3 neighboring test classes to learn project conventions

### Step 2: Generate Test Cases

1. Analyze ALL code branches, including:
   - Success paths
   - Error/exception paths
   - Validation logic
   - Private/protected methods called by the target
   - Security annotations (if present)
2. Apply the INCLUDE/EXCLUDE rules strictly
3. Output the list of test cases in the format below — do NOT generate test code yet

#### Test Case Output Format

```
## Test Cases for {ClassName}.{methodName}

### 1. {testMethodName}
- **Given:** {preconditions/input state}
- **When:** {action being tested}
- **Then:** {expected outcome}
- **Code branch:** {which code path this covers}

### 2. {testMethodName}
...
```

#### Naming Convention
Test method name format: `{testedMethod}_{givenState}_{expectedOutcome}`

Examples:
- `calculateTotal_validProducts_returnsSum`
- `calculateTotal_emptyList_throwsIllegalArgumentException`
- `getUser_unauthorized_returns401`

### Step 3: Ask for User Review

After outputting test cases, ask: "Test cases are ready. Proceed with generating
test code?" Use a user-question tool if your agent provides one; otherwise ask
in conversation and wait for the answer.

- If the user approves, proceed to Step 4.
- If the user declines or has not answered, stop and wait for further instructions.

### Step 4: Generate Test Code

1. Determine code type and apply the matching rules:
   - **Controller** → Apply `controller-test-rules.md` (use `@WebMvcTest`, MockMvc patterns)
   - **Service / Domain logic** → Apply `domain-service-rules.md` (use `@ExtendWith(MockitoExtension.class)`, Mockito patterns)
   - **Repository / Messaging / Other types** → Apply `domain-service-rules.md` as baseline; inform the user that type-specific rules are not yet available
   - **All Java code** → Always apply `java-test-template.md`, `argument-matching.md`, `json-serialization.md` regardless of code type
2. If an existing test class was found in Step 1, add new test methods to it (do not create a duplicate file)
3. Generate tests following all rules and the test cases from Step 2
4. Create or update the test file using the available file-editing tool

### Step 5: Verify Compilation and Execution

1. Run compilation and fix any issues (max 5 attempts — see `compilation-verification.md`)
2. Run the generated test class to verify all tests pass (see `test-execution-verification.md`)
3. Fix any failing tests — do NOT modify production code
4. If a test cannot be fixed after 3 attempts, remove it and inform the user

---

## Troubleshooting

### Target file not found
If the specified target does not exist, inform the user with the exact path you searched and ask for clarification.

### Unsupported language
If the target code is in a language without specific rules (not Java), apply only the general rules and inform the user that language-specific conventions may need manual review.

### Compilation keeps failing
If compilation fails after 5 attempts:
1. Stop and show the user the remaining errors
2. Suggest possible causes (missing dependencies, incompatible versions)
3. Ask the user to resolve the build issue before continuing

### Tests fail due to production code behavior
If tests fail because the production code behaves differently than expected:
1. Do NOT modify production code
2. Fix the test to match actual behavior
3. If the behavior seems like a bug, add a comment: `// NOTE: current behavior may be a bug — {description}`

---

## Example

```
User says: "/generate-tests src/main/java/com/example/service/OrderService.java"

Step 1: Agent reads rules, reads OrderService.java, reads OrderRequest.java,
        Order.java, OrderRepository.java (dependencies), checks for
        existing OrderServiceTest.java

Step 2: Agent outputs 7 test cases covering:
        - createOrder success path
        - createOrder with invalid request (validation)
        - processPayment success
        - processPayment failure
        - calculateTotal with products
        - calculateTotal with empty list
        - cancelOrder for non-existent order

Step 3: Agent asks user to review. User says "Yes, generate tests".

Step 4: Agent generates OrderServiceTest.java with @ExtendWith(MockitoExtension.class),
        mocked repository and payment service, 7 test methods.

Step 5: Agent runs `mvn test -Dtest=OrderServiceTest -q`, all tests pass.

Result: Complete test file delivered with 7 passing tests.
```

---

## Rules Reference

**CRITICAL: You MUST read and apply all relevant rules from the `./rules/tests/` directory.**

All references below resolve from this skill directory. General rules are bundled
locally; read these copies when running the skill.

### General Rules (Always Apply)
- `./rules/tests/general/test-case-generation-strategy.md` - INCLUDE/EXCLUDE criteria
- `./rules/tests/general/naming-conventions.md` - Test naming format
- `./rules/tests/general/general-principles.md` - Core testing principles (Given-When-Then, actual/expected)
- `./rules/tests/general/technology-stack-detection.md` - Detect language and framework
- `./rules/tests/general/what-makes-good-test.md` - Clarity, Completeness, Conciseness, Resilience
- `./rules/tests/general/cleanly-create-test-data.md` - Use helpers and builders for test data
- `./rules/tests/general/keep-cause-effect-clear.md` - Effects follow causes immediately
- `./rules/tests/general/no-logic-in-tests.md` - KISS > DRY, avoid logic in assertions
- `./rules/tests/general/keep-tests-focused.md` - One scenario per test
- `./rules/tests/general/test-behaviors-not-methods.md` - Separate tests for behaviors
- `./rules/tests/general/verify-relevant-arguments-only.md` - Only verify relevant mock arguments
- `./rules/tests/general/prefer-public-apis.md` - Test public APIs over private methods
- `./rules/tests/general/existing-test-awareness.md` - Check for existing tests, match project conventions
- `./rules/tests/general/code-context-analysis.md` - Read dependencies before writing tests

### Java Unit Tests
- `./rules/tests/java/unit/java-test-template.md` - Basic template, FORBIDDEN annotations
- `./rules/tests/java/unit/json-serialization.md` - Use explicit JSON literals
- `./rules/tests/java/unit/argument-matching.md` - Use ArgumentCaptor, not any()
- `./rules/tests/java/unit/logging-rules.md` - OutputCaptureExtension for logs
- `./rules/tests/java/unit/domain-service-rules.md` - Mockito patterns for services
- `./rules/tests/java/unit/controller-test-rules.md` - @WebMvcTest and MockMvc patterns for controllers

### Post-Generation
- `./rules/tests/post-generation/compilation-verification.md` - Verify compilation
- `./rules/tests/post-generation/test-execution-verification.md` - Verify tests pass
