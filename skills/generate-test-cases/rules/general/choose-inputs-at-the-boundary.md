---
title: Choose Inputs at the Boundary
impact: HIGH
impactDescription: prevents tests whose oracle is correct but whose input is too far from the limit to detect a wrong limit
tags: tests, boundary-values, equivalence-partitioning, validation, oracle-strength
---

## Choose Inputs at the Boundary

A test can have a perfectly strong assertion and still detect nothing, because its input
sits far from the limit the code checks. When the code compares a value against a constant,
**the test's input must sit adjacent to that constant**: the last value that is accepted and
the first that is rejected.

### The Check

**If the constant in the production code could be changed and this test would still pass,
the input is idle.** A test that submits 1 000 000 against a limit of 10 000 passes whether
the limit is 10 000, 100 000 or 500 000. It confirms that something is rejected; it does not
pin where.

### The Stopping Condition

**One pair per comparison in the code under test** — not a sweep of values, and not a pair
per field.

- For each comparison, two inputs: the boundary value itself and one step past it.
- For the values inside a partition, one representative is enough. Three more valid amounts
  exercise the same branch and add nothing.
- Where a constraint exists but the code has no branch on it, no boundary test — see the
  EXCLUDE criteria in `test-case-generation-strategy.md`.

"One step" is the smallest step in the value's own domain: one minor unit for a monetary
amount, one character for a length, one element for a size, one day for a date. For a money
amount with two decimal places, the step past 10000.00 is 10000.01, not 10001.

### Problem: An Input Far From the Limit

The service rejects a transfer whose amount exceeds a daily limit of 10 000.

**Incorrect:**

```java
@Test
void transfer_amountAboveDailyLimit_isRejected() {
    // Given
    var request = new TransferRequest("DE89370400440532013000", new BigDecimal("1000000.00"), "EUR");

    // When / Then
    assertThatThrownBy(() -> transferService.transfer(request))
            .isInstanceOf(DailyLimitExceededException.class);
}
// Raise the limit to 100 000 and 1 000 000 is still rejected. The real edge,
// 10 000.00 against 10 000.01, is never touched.
```

**Correct:**

```java
@Test
void transfer_amountEqualToDailyLimit_isAccepted() {
    // Given
    var request = new TransferRequest("DE89370400440532013000", new BigDecimal("10000.00"), "EUR");

    // When
    var actualResponse = transferService.transfer(request);

    // Then
    assertThat(actualResponse.getStatus()).isEqualTo(TransferStatus.COMPLETED);
}

@Test
void transfer_amountOneCentAboveDailyLimit_isRejected() {
    // Given
    var request = new TransferRequest("DE89370400440532013000", new BigDecimal("10000.01"), "EUR");

    // When / Then
    assertThatThrownBy(() -> transferService.transfer(request))
            .isInstanceOf(DailyLimitExceededException.class);
}
```

The pair fails if the limit moves in either direction. Either test alone does not.

### Where to Look for Comparisons

- Relational operators on numbers, lengths, sizes and dates: `>`, `>=`, `<`, `<=`
- Declarative constraints the framework enforces: `@Size`, `@Min`, `@Max`, `@Length`,
  `@Positive`, `@Past`, `@Future`
- Explicit size or emptiness branches on a collection
- String length and format limits applied before persistence

A two-sided constraint has two boundaries. `@Size(min = 2, max = 30)` gives four inputs —
2 accepted, 1 rejected, 30 accepted, 31 rejected — and no values in between.

### Related

- `test-case-generation-strategy.md` — whether a case belongs at all; this rule decides the
  input once it does.
- `assert-values-not-shapes.md` — the complementary failure, where the input is right and
  the assertion is idle.
