---
title: Assert Every Field the Code Writes
impact: HIGH
impactDescription: closes the gap where a captured object is checked field by field and the one field a bug would change is never asserted
tags: tests, assertions, argument-captor, completeness, oracle-strength
---

## Assert Every Field the Code Writes

When the code under test builds or mutates an object, the set of fields that must be
asserted is decided by the production code, not by judgment: **every field the code assigns
on the path under test is asserted by some test that covers that path.**

This is the gap that looks most rigorous from the outside. The test has a captor, named
field assertions and no wildcard matchers — it looks exhaustive. It is exhaustive only of
the fields the author happened to think of, and the field nobody thought of is the one a
bug changes silently.

### The Stopping Condition

Without one, "assert the relevant fields" under-fills and "assert every field" over-fills.
Derive the list from the code instead:

1. Read the method under test. List every field it assigns on the path being tested —
   constructor arguments, setters, builder calls, mapper output.
2. Split that list in two. A field whose value follows from the input by **identity** — the
   code copies it across and decides nothing — is asserted together with the other identity
   fields, in the test named for that input. A field whose value the code **decides** — a
   default, a clock, a generator, a transformation such as `request.getIban().substring(0, 8)`
   — is a behavior of its own and gets its own test, named for that decision.
3. Every field on the list is asserted by one of those tests. Which test asserts it is a
   naming question; whether it is asserted at all is not.
4. Fields **not** on the list get none. Fields left at their default, populated by the
   framework, or written by code outside this method are out of scope; asserting them
   turns the test into a change-detector that breaks on unrelated edits.

The list ends where the method's assignments end.

For the method below the list is four fields, and the split gives two tests:

```java
public void transfer(TransferRequest request) {
    Transfer transfer = new Transfer();
    transfer.setRecipientIban(request.getIban());    // identity
    transfer.setAmount(request.getAmount());         // identity
    transfer.setCurrency(request.getCurrency());     // identity
    transfer.setCreatedAt(Instant.now(clock));       // decision
    transferRepository.save(transfer);
}
```

| Field | Value comes from | Test that asserts it |
|---|---|---|
| `recipientIban`, `amount`, `currency` | the request, unchanged — identity | `transfer_validRequest_persistsTransferWithRequestedCurrency` |
| `createdAt` | the injected `Clock` — a decision | `transfer_validRequest_stampsCreatedAtFromClock` |

### The Check

For each field on the list, name the test that asserts it. **If you cannot name one, that is
the gap** — whether the tests are split or not. Giving a field its own test is not dropping
it; leaving it with no test anywhere is.

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

A field assigned from a clock, a random source or a generator is a decision, so it gets its
own test — and the assertion in it is still an equality check, because fixing the source is
what makes one possible:

```java
@Test
void transfer_validRequest_stampsCreatedAtFromClock() {
    // Given — the Clock injected into the service is fixed at 2026-01-01T00:00:00Z
    var captor = ArgumentCaptor.forClass(Transfer.class);

    // When
    transferService.transfer(newRequest());

    // Then
    verify(transferRepository).save(captor.capture());
    assertThat(captor.getValue().getCreatedAt()).isEqualTo(Instant.parse("2026-01-01T00:00:00Z"));
}
```

Leaving the field with no assertion anywhere, because its value is awkward to pin, is how the
assignment goes unchecked; `isNotNull()` in its place is the shape assertion
`assert-values-not-shapes.md` rules out. Injecting a fixed clock costs less than the gap it
closes.

### Do Not Substitute Whole-Object Equality

```java
// Looks like it satisfies this rule. It does not.
assertThat(actualTransfer).isEqualTo(expectedTransfer);
```

It asserts the untouched fields too, so it breaks when an unrelated field is added, and it
delegates the comparison to `equals()`, which entities commonly define on id alone — in
which case it asserts almost nothing. Assert the written fields by name.

### When No Assertion Can Fail

Enumerating the assigned fields sometimes turns up one that nothing ever reads — a field set
on an object the method then discards, a message composed and never sent. No test can detect
a change to it, because the change has no observable consequence.

Do not invent an assertion for it, and do not reach into internals to manufacture one. This
is a finding about the production code: report it as dead code or missing wiring, and leave
it out of the test. Filing it as a test gap produces tests that assert on implementation
detail and fail on every refactor.

### Related

- `verify-relevant-arguments-only.md` — the arguments of the call, where this rule stops: that
  rule decides `eq(...)` vs `any(...)`, this one decides the fields inside a captured object.
- `assert-values-not-shapes.md` — the same failure one level up, on the value a method returned.
- `keep-tests-focused.md` — how the identity/decision split above lands as separate tests.
