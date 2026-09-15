---
title: Keep Tests Focused
impact: HIGH
impactDescription: ensures each test verifies one specific scenario for clear failure messages
tags: tests, focused, single-scenario, single-assertion
---

## Keep Tests Focused

Each test should exercise one specific scenario. Multiple scenarios in one test make failures hard to diagnose.

### Problem: Multiple Scenarios in One Test

**Incorrect:**

```java
@Test
void withdrawFromAccount() {
    Transaction transaction = account.deposit(usd(5));

    // Scenario 1: withdraw within balance
    assertThat(account.withdraw(usd(5))).isEqualTo(isOk());

    // Scenario 2: withdraw over balance
    assertThat(account.withdraw(usd(1))).isEqualTo(isRejected());

    // Scenario 3: withdraw with overdraft
    account.setOverdraftLimit(usd(1));
    assertThat(account.withdraw(usd(1))).isEqualTo(isOk());
}
// This tests three scenarios, not one!
```

**Correct:**

```java
@Test
void withdraw_withinBalance_succeeds() {
    depositAndSettle(usd(5));

    assertThat(account.withdraw(usd(5))).isEqualTo(isOk());
}

@Test
void withdraw_overBalance_isRejected() {
    depositAndSettle(usd(5));

    assertThat(account.withdraw(usd(6))).isEqualTo(isRejected());
}

@Test
void withdraw_withinOverdraftLimit_succeeds() {
    depositAndSettle(usd(5));
    account.setOverdraftLimit(usd(1));

    assertThat(account.withdraw(usd(6))).isEqualTo(isOk());
}
```

### Benefits of Focused Tests

1. **Clear failure messages** - you know exactly what broke
2. **Descriptive names** - each test name describes one scenario
3. **Easy to maintain** - changing one scenario doesn't affect others
4. **Better coverage visibility** - see which scenarios are tested

### When Multiple Assertions Are OK

Multiple assertions are fine when verifying **one behavior** with multiple properties:

```java
@Test
void createUser_validInput_returnsCompleteUser() {
    User actualUser = userService.create("john@test.com", "John");

    // All assertions verify the same behavior: user creation
    assertThat(actualUser.getId()).isNotNull();
    assertThat(actualUser.getEmail()).isEqualTo("john@test.com");
    assertThat(actualUser.getName()).isEqualTo("John");
    assertThat(actualUser.getCreatedAt()).isNotNull();
}
```

### One Trigger Per Test, Even When the Outcome Is Shared

The section above allows many assertions about **one** behaviour. It does not allow
many **causes** in one test. Validation is where this goes wrong most often: several
constraints share a single outcome — "the form comes back with errors" — which makes
merging them look like one scenario.

**Incorrect:**

```java
@Test
void processCreationForm_blankNamesAndCity_returnsFormWithFieldErrors() throws Exception {
    mockMvc.perform(post("/owners/new").param("firstName", "")
                    .param("lastName", "")
                    .param("city", ""))
            .andExpect(model().attributeHasFieldErrors("owner", "firstName", "lastName", "city"));
}
```

Three constraints are tripped at once. When this goes red it does not say which one
regressed — and if two of the three stop rejecting, it still passes on the third.

**Correct** — one constraint per test, every other field valid:

```java
@Test
void processCreationForm_blankFirstName_returnsFormWithFirstNameError() throws Exception {
    mockMvc.perform(post("/owners/new").param("firstName", "")
                    .param("lastName", "Bloggs")
                    .param("address", "123 Caramel Street")
                    .param("city", "London")
                    .param("telephone", "1316761638"))
            .andExpect(model().attributeHasFieldErrors("owner", "firstName"));
}
```

...and one more each for `lastName` and `city`.

Keep every field except the one under test valid, so the only reason the request can
be rejected is the constraint being tested. The check: if you could delete one of the
inputs and still have a failing case for a different reason, those are separate
scenarios.

A test name that needs "and" to describe its input is the same signal as the "and" in
the list below.

### Signs Your Test Is Not Focused

- Test name uses "and" (e.g., `testDepositAndWithdraw`)
- Multiple "When" or "Act" sections
- State changes between assertions
- Hard to name the test concisely
- Test is longer than 10-15 lines

### Split Unfocused Tests

Ask: "If this test fails, will I know exactly which scenario broke?"

If not, split it into multiple tests.