---
title: Match the Assertion to the Test Name
impact: HIGH
impactDescription: prevents tests that pass for reasons unrelated to the behavior their name claims
tags: tests, assertions, naming, error-handling, oracle-strength
---

## Match the Assertion to the Test Name

A test name states a cause and an outcome: `transfer_toBlockedAccount_isRejected`. Many
causes share one outcome — HTTP 400, `ValidationException`, `false`, `Optional.empty()` are
produced by every rejecting path there is. An assertion that checks only the shared part
passes for reasons that have nothing to do with the cause in the name, and the link between
the two survives only in the author's head.

**Assert the part of the outcome that only this cause produces.**

### The Check

Name two other inputs that reach the same outcome. **If this test's assertions would pass
for them as well, the assertion does not test what the name claims.**

### Problem: An Outcome Several Causes Share

**Incorrect:**

```java
@Test
void transfer_toBlockedAccount_isRejected() throws Exception {
    // Given
    when(accountClient.isBlocked("DE89370400440532013000")).thenReturn(true);

    // When / Then
    mockMvc.perform(post("/transfers")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content("{\"iban\":\"DE89370400440532013000\",\"amount\":250.00,\"currency\":\"EUR\"}"))
            .andExpect(status().isBadRequest());
}
// A malformed IBAN and a missing amount also return 400. This test passes if the
// blocked-account check is deleted outright, as long as something else rejects the request.
```

**Correct:**

```java
@Test
void transfer_toBlockedAccount_returns400WithRecipientBlockedCode() throws Exception {
    // Given
    when(accountClient.isBlocked("DE89370400440532013000")).thenReturn(true);

    // When / Then
    mockMvc.perform(post("/transfers")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content("{\"iban\":\"DE89370400440532013000\",\"amount\":250.00,\"currency\":\"EUR\"}"))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.errorCode").value("RECIPIENT_BLOCKED"));

    verify(transferRepository, never()).save(any());
}
```

The error code is what distinguishes this cause from the others that return 400. The
`never()` verification asserts the other half of "rejected" — that the effect did not happen
anyway.

### The Same Failure With Exceptions

Asserting the exception type alone is the common form, because one exception type usually
covers every validation failure in a service.

**Incorrect:**

```java
// Every rejected transfer throws ValidationException — currency, IBAN, amount, all of them
assertThatThrownBy(() -> transferService.transfer(request))
        .isInstanceOf(ValidationException.class);
```

**Correct:**

```java
assertThatThrownBy(() -> transferService.transfer(request))
        .isInstanceOfSatisfying(ValidationException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.CURRENCY_MISMATCH));
```

Where the exception carries no code, assert on the part of the message that names the cause
(`hasMessageContaining("currency")`). A code is preferable; a message is better than the
type alone.

### When There Is No Discriminator

Sometimes the outcome genuinely carries nothing that separates this cause from the others.
Two honest responses, in this order:

1. **Rename the test to what it actually asserts.** `transfer_invalidRequest_returns400` is
   a true name for an assertion on the status alone. A name that claims more than the
   assertion checks is worse than a modest one, because it is read as coverage that exists.
2. **Report the missing distinction.** An API that answers every rejection identically is
   hard to use and hard to test. That is a finding about the production code, not something
   the test can repair.

Do not close the gap by asserting on internals — a spy on the validator, a check that some
private branch ran. That couples the test to the implementation and fails on the next
refactor while still not testing the behavior.

### Related

- `naming-conventions.md` — the `{method}_{state}_{outcome}` format this rule holds the
  assertion to.
- `test-case-generation-strategy.md` — never merge 400, 401 and 403 into one case; this rule
  is the same requirement applied inside a single status code.
