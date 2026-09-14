---
title: Logging Output Verification
impact: MEDIUM
impactDescription: enables testing of log output and console messages
tags: java, tests, logging, output-capture, stdout, stderr
---

## Logging Output Verification

Use `OutputCaptureExtension` to capture and verify log output in tests.

### First: Decide Whether to Test the Log at All

A log line is usually an implementation detail. Asserting on it couples the test to
wording that any refactor may change, which is exactly what
`general-principles.md` ("test behaviour, not implementation") and
`what-makes-good-test.md` ("Resilience") warn against. Do not add a log assertion
just because the method happens to log.

Assert on log output only when the log **is** the observable contract:

- the method's entire job is to emit a record (audit trail, security event)
- there is no other observable effect (a `void` method whose only outcome is the log)
- a specific message is required by an operational contract — an alert rule, a log
  parser, a compliance requirement

Otherwise assert on the return value or the mock interaction instead, and let the
logging change freely.

### Rules

- When testing log output or stdout/stderr, use `@ExtendWith(OutputCaptureExtension.class)`
- Assert the captured output using the `CapturedOutput` parameter

**Incorrect:**

```java
@Test
void processOrder_success_logsMessage() {
    // No way to verify logs
    orderService.processOrder(order);

    // Can't assert anything about logging
}

// Using manual System.out capture - fragile
@Test
void processOrder_success_logsMessage() {
    ByteArrayOutputStream outContent = new ByteArrayOutputStream();
    System.setOut(new PrintStream(outContent));

    orderService.processOrder(order);

    assertThat(outContent.toString()).contains("Order processed");
    System.setOut(System.out); // Don't forget to reset!
}
```

**Correct:**

```java
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.boot.test.system.CapturedOutput;
import org.springframework.boot.test.system.OutputCaptureExtension;

@ExtendWith(OutputCaptureExtension.class)
class OrderServiceTest {

    private OrderService orderService = new OrderService();

    @Test
    void processOrder_success_logsOrderId(CapturedOutput output) {
        // Given
        var order = new Order("order-123", "product-1");

        // When
        orderService.processOrder(order);

        // Then
        assertThat(output.getOut()).contains("Processing order: order-123");
    }

    @Test
    void processOrder_failure_logsError(CapturedOutput output) {
        // Given
        var invalidOrder = new Order(null, "product-1");

        // When
        assertThatThrownBy(() -> orderService.processOrder(invalidOrder))
                .isInstanceOf(IllegalArgumentException.class);

        // Then
        assertThat(output.getErr()).contains("Invalid order");
    }

    @Test
    void cacheHit_secondCall_noLogOutput(CapturedOutput output) {
        // Given
        var key = "key-1";

        // When
        cacheService.getData(key); // First call - cache miss
        cacheService.getData(key); // Second call - cache hit

        // Then - verify log message appeared exactly once
        assertThat(output.getOut()).containsOnlyOnce("Loading from database");
    }
}
```

### CapturedOutput Methods

```java
// Get stdout content
output.getOut()

// Get stderr content
output.getErr()

// Get all output (stdout + stderr)
output.getAll()

// Use with standard assertions
assertThat(output.getOut()).contains("expected message");
assertThat(output.getOut()).doesNotContain("error");
assertThat(output.getErr()).isEmpty();
```

### Dependency Note

`OutputCaptureExtension` and `CapturedOutput` come from the `spring-boot-test` dependency (`org.springframework.boot:spring-boot-test`). This extension does **NOT** start a Spring context — it only captures `System.out`/`System.err`, so it is fully compatible with unit tests (no `@SpringBootTest` needed).

For non-Spring projects, use alternative approaches:
- SLF4J's `ListAppender` to capture log events programmatically
- JUnit 5's `@ExtendWith` with a custom extension that redirects stdout/stderr

### Use Cases

1. **Verifying log messages** - ensure important events are logged
2. **Cache behavior** - verify cache hits/misses via log output
3. **Error logging** - verify errors are properly logged
4. **Debug output** - verify debug information is output correctly