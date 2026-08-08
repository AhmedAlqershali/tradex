---
name: Sanctum guard switching in tests
description: Laravel feature-test bearer identity changes can be masked by a cached Sanctum request guard.
---

When a single Laravel feature test makes sequential requests with different Sanctum bearer tokens, call `Auth::forgetGuards()` between identity switches.

**Why:** The in-process test application can retain the first resolved Sanctum user, causing a valid later token to hit role middleware as the wrong user and return 403.

**How to apply:** Use this only at test identity boundaries; do not weaken or bypass production authentication or role middleware.