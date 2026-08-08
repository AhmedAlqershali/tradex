---
name: PHPUnit throttle isolation
description: Prevent shared Laravel throttle state from causing sequential feature-test failures.
---

Laravel's PHPUnit environment uses the in-memory `array` cache while the application applies global `api` throttling plus named `auth` and `ai` limiters. Because the cache instance lives for the test process, counters can leak between feature tests and produce false HTTP 429 failures.

**Why:** Focused and full suites previously accumulated throttle state across requests and tests, masking expected 200/401/403/404/422 responses as 429s.

**How to apply:** Flush the configured test cache in the shared feature-test base `setUp()` after the framework boots. Keep production middleware, limiter definitions, and limits unchanged; explicit rate-limit tests can still build their counters within one test.