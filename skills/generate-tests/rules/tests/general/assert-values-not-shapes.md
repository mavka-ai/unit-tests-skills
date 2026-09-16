---
title: Assert the Value, Not the Shape of the Answer
impact: HIGH
impactDescription: prevents assertions that hold for every input and therefore can never fail
tags: tests, assertions, oracle-strength, tautology
---

## Assert the Value, Not the Shape of the Answer

An assertion earns its place only if some input would make it fail. Assertions on the
**shape** of a result — that it is non-null, that it has the expected type, that a
collection is not empty, that a message carries the expected key — hold for every
successful run, whatever the operation actually computed.

Assert the **value** the operation produced: the rendered text, the computed amount, the
resulting status, the elements in the collection.

### The Check

Before accepting an assertion, ask: **would it still hold if this test's input were a
different valid input?** If yes, it is asserting the shape, and the values that are the
point of the operation are unchecked.

### Problem: True by Construction

**Incorrect:**

```java
@Test
void transfer_validRequest_returnsConfirmation() {
    // Given
    var request = new TransferRequest("DE89370400440532013000", new BigDecimal("250.00"), "EUR");

    // When
    var actualResponse = transferService.transfer(request);

    // Then
    assertThat(actualResponse).isNotNull();
    assertThat(actualResponse.getMessageKey()).isEqualTo("transfer.confirmation");
}
// Every successful transfer returns that key. Change the amount to 4000.00 and the
// recipient to another IBAN and the test still passes — it cannot tell the two apart.
```

**Correct:**

```java
@Test
void transfer_validRequest_returnsConfirmationNamingAmountAndRecipient() {
    // Given
    var request = new TransferRequest("DE89370400440532013000", new BigDecimal("250.00"), "EUR");

    // When
    var actualResponse = transferService.transfer(request);

    // Then
    String expectedMessage = "Sent 250.00 EUR to DE89370400440532013000";
    assertThat(actualResponse.getMessage()).isEqualTo(expectedMessage);
    assertThat(actualResponse.getStatus()).isEqualTo(TransferStatus.COMPLETED);
}
```

### The Same Failure in Collections

**Incorrect:**

```java
var actualTransfers = transferService.findByAccount("ACC-1");

assertThat(actualTransfers).isNotEmpty();
assertThat(actualTransfers).hasSize(2);
```

Size survives any change to which transfers were selected or how they were ordered.

**Correct:**

```java
var actualTransfers = transferService.findByAccount("ACC-1");

assertThat(actualTransfers)
        .extracting(Transfer::getRecipientIban)
        .containsExactly("DE89370400440532013000", "FR1420041010050500013M02606");
```

### When a Shape Assertion Is the Right One

Two cases, both narrow:

1. **The shape is the behavior.** An endpoint whose contract is "returns 204 with an empty
   body" is tested by asserting exactly that. An operation specified to return an empty
   collection for an unknown account is tested with `isEmpty()`.
2. **As a precondition, alongside a value assertion.** A null check that guards the
   navigation to the value you actually assert is fine. On its own it is not an assertion.

Everywhere else, a shape assertion means the value assertion has not been written yet.

### Related

- `assert-every-field-the-code-writes.md` — the same failure one level down, inside an
  object the code built.
- `match-the-assertion-to-the-test-name.md` — for outcomes that several different inputs
  share.
