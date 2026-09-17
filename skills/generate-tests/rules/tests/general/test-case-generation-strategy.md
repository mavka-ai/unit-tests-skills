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
- **Validation constraints**: Generate NEGATIVE test cases for each validation annotation (invalid input that should fail validation)
- **Custom validators**: Generate test cases that trigger validation failure

### EXCLUDE:
- Redundant input variations that add no distinct behavior, condition,
  or boundary coverage — see Decision Strategy
- Collection size variations (1, 2, 3 elements) unless code has EXPLICIT size-dependent logic
- Speculative cases (exotic Unicode, massive payload) unless code explicitly handles them
- Null arguments unless parameter is `@Nullable` or `Optional`

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

Include a test case when it covers a distinct behavior, an independent
condition, or a boundary required by the contract or implemented in the code.

Two cases are not duplicates merely because they produce the same return
value, HTTP status, or exception type. Keep separate cases when each checks
a different condition that can fail independently.

Exclude additional input variations within the same equivalence partition
when they exercise the same condition and add no distinct behavior or
boundary coverage.

For example:

- A deleted account and an expired account both reject login with
  `IllegalStateException`. Keep both cases: either rejection condition
  can regress independently.
- Accounts expired by five and ten days exercise the same condition.
  One representative is enough unless the contract or code distinguishes
  those durations.

**FORBIDDEN:** Using "2xx", "4xx", "5xx" instead of concrete status codes (200, 400, 401, 403, 500).
