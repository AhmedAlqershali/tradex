---
name: Laravel test encryption key
description: Environment constraint affecting imported Laravel PHPUnit runs
---

Imported Laravel environments may not define `APP_KEY` for CLI PHPUnit runs. Without a process-only testing key, password-reset tests can fail because the password broker receives a null hash key, and generic encryption tests fail with `MissingAppKeyException`.

**Why:** The application workflow can be healthy while the test process lacks the runtime encryption setting; this is test-environment setup, not evidence of an application regression.

**How to apply:** When running Laravel QA, preserve the workspace and use a temporary `APP_KEY` environment variable for the command only. Never write the key to project files or expose secret values.