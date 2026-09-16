---
title: Assert Every Field the Code Writes
impact: HIGH
impactDescription: closes the gap where a captured object is checked field by field and the one field a bug would change is never asserted
tags: tests, assertions, argument-captor, completeness, oracle-strength
---

## Assert Every Field the Code Writes

When a test captures an object that the code under test built or mutated, the set of
fields to assert is decided by the production code, not by judgment: **assert every field
the code assigns on the path under test.**

This is the gap that looks most rigorous from the outside. The test has a captor, named
field assertions and no wildcard matchers — it looks exhaustive. It is exhaustive only of
the fields the author happened to think of, and the field nobody thought of is the one a
bug changes silently.

### The Stopping Condition

Without one, "assert the relevant fields" under-fills and "assert every field" over-fills.
Derive the list from the code instead:

1. Read the method under test. List every field it assigns on the path being tested —
   constructor arguments, setters, builder calls, mapper output.
2. Every field on that list gets an assertion.
3. Fields **not** on that list get none. Fields left at their default, populated by the
   framework, or written by code outside this method are out of scope; asserting them
   turns the test into a change-detector that breaks on unrelated edits.

The list ends where the method's assignments end.

### Problem: The Field Nobody Asserted

**Incorrect:**

```java
@Test
void transfer_validRequest_persistsTransfer() {
    // Given
    var request = new TransferRequest("DE89370400440532013000", new BigDecimal("250.00"), "EUR");
    var captor = ArgumentCaptor.forClass(Transfer.class);

    // When
    transferService.transfer(request);

    // Then
    verify(transferRepository).save(captor.capture());
    Transfer actualTransfer = captor.getValue();
    assertThat(actualTransfer.getRecipientIban()).isEqualTo("DE89370400440532013000");
    assertThat(actualTransfer.getAmount()).isEqualByComparingTo("250.00");
    // The service also assigns currency. It is never asserted, so code that
    // overwrites it with a system default keeps this test green.
}
```

**Correct:**

```java
@Test
void transfer_validRequest_persistsTransferWithRequestedCurrency() {
    // Given
    var request = new TransferRequest("DE89370400440532013000", new BigDecimal("250.00"), "EUR");
    var captor = ArgumentCaptor.forClass(Transfer.class);

    // When
    transferService.transfer(request);

    // Then
    verify(transferRepository).save(captor.capture());
    Transfer actualTransfer = captor.getValue();
    assertThat(actualTransfer.getRecipientIban()).isEqualTo("DE89370400440532013000");
    assertThat(actualTransfer.getAmount()).isEqualByComparingTo("250.00");
    assertThat(actualTransfer.getCurrency()).isEqualTo("EUR");
}
```

### Fields Whose Value Is Not Fixed

A field assigned from a clock, a random source or a generator still gets an assertion — it
just cannot be an equality check against a literal. Assert the property the code is
responsible for, and fix the source so there is one:

```java
// The service stamps createdAt from an injected Clock — fix the clock, assert the value
assertThat(actualTransfer.getCreatedAt()).isEqualTo(Instant.parse("2026-01-01T00:00:00Z"));
```

Dropping a field because its value is awkward to pin is how the assignment goes unchecked.
Injecting a fixed clock costs less than the gap it closes.

### Do Not Substitute Whole-Object Equality

```java
// Looks like it satisfies this rule. It does not.
assertThat(actualTransfer).isEqualTo(expectedTransfer);
```

It asserts the untouched fields too, so it breaks when an unrelated field is added, and it
delegates the comparison to `equals()`, which entities commonly define on id alone — in
which case it asserts almost nothing. Assert the written fields by name.

### Relationship to `verify-relevant-arguments-only.md`

The two rules act on different things and do not conflict:

- `verify-relevant-arguments-only` governs the **arguments of the call** — which parameters
  to pin with `eq(...)` and which to leave as `any(...)`, because they belong to a behavior
  a different test owns.
- This rule governs the **fields inside an object the code under test built**. Those fields
  are the behavior under test, so there is no irrelevant one among them.

### When No Assertion Can Fail

Enumerating the assigned fields sometimes turns up one that nothing ever reads — a field set
on an object the method then discards, a message composed and never sent. No test can detect
a change to it, because the change has no observable consequence.

Do not invent an assertion for it, and do not reach into internals to manufacture one. This
is a finding about the production code: report it as dead code or missing wiring, and leave
it out of the test. Filing it as a test gap produces tests that assert on implementation
detail and fail on every refactor.
