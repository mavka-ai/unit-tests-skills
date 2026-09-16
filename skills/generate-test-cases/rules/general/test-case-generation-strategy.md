---
title: Test Case Generation Strategy
impact: HIGH
impactDescription: ensures comprehensive coverage without redundant tests
tags: tests, test-cases, strategy, coverage, branches
---

## Test Case Generation Strategy

Apply strict INCLUDE/EXCLUDE criteria to generate meaningful test cases that cover all code branches without redundancy.

### INCLUDE:
- Each distinct code branch and outcome (success paths, error handling)
- Each unique return value or exception the method can produce
- For HTTP methods: separate cases for status 400, 401, 403 (never merge these)
- Use concrete status codes only
- **Validation constraints**: Generate a NEGATIVE test case for each constraint declaration on each field (invalid input that should fail validation)
- **Custom validators**: Generate test cases that trigger validation failure

### EXCLUDE:
- Duplicate scenarios — two cases that cannot diverge. Judge by whether what each case pins can
  change independently, not by whether today's results look alike: two fields that each declare
  their own maximum length are not duplicates, because either limit can be edited without the
  other and only its own case will then go red
- Collection size variations (1, 2, 3 elements) unless code has EXPLICIT size-dependent logic
- Speculative cases (exotic Unicode, massive payload) unless code explicitly handles them
- Null arguments unless parameter is `@Nullable` or `Optional`
- Multiple tests for same exception type

**Incorrect:**

```java
// Merging different HTTP status codes
@Test
void getUser_invalidRequest_returns4xx() { ... }

// Testing collection sizes without explicit logic
@Test
void processItems_oneItem_success() { ... }
@Test
void processItems_twoItems_success() { ... }
@Test
void processItems_threeItems_success() { ... }

// Testing null without @Nullable annotation
@Test
void calculate_nullInput_throwsException() { ... }
```

**Correct:**

```java
// Separate tests for each HTTP status
@Test
void getUser_invalidInput_returns400() { ... }
@Test
void getUser_unauthenticated_returns401() { ... }
@Test
void getUser_forbidden_returns403() { ... }

// Single test for collection processing (no size-dependent logic)
@Test
void processItems_validList_returnsProcessedResult() { ... }

// Only test null if parameter is @Nullable
@Test
void calculate_nullableInput_returnsDefault() { ... } // only if @Nullable
```

### CRITICAL: Private/Protected Methods

When a method calls private/protected methods, cover ALL their execution paths indirectly via different inputs to the public method.

### Decision Strategy

Before adding each test case, ask:
1. Does it trigger a DIFFERENT code branch? If no -> skip
2. Does it produce a DIFFERENT observable outcome? If no -> skip
3. Does the code EXPLICITLY check this condition? If no -> skip

**Count declarations, not branches.** One negative case per declared constraint, on every
field that declares one. Each declaration can be edited on its own, so each needs its own case
to go red when it changes. The three questions above do not reach these cases: a framework
validates declared constraints before the code under test runs and funnels every failure into
one shared path, so all three answer "skip" for every field.

**FORBIDDEN:** Using "2xx", "4xx", "5xx" instead of concrete status codes (200, 400, 401, 403, 500).