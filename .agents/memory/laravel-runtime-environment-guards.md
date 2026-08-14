---
name: Laravel runtime environment guards
description: Environment lookup behavior for guarded Laravel commands that run during deployment startup.
---

Deployment-time safety switches should read the live process environment, with Laravel configuration only as a fallback for non-secret defaults.

**Why:** Laravel's environment repository is immutable after bootstrap, so tests or long-lived processes that change environment values after startup can otherwise observe stale values and incorrectly skip a guarded operation.

**How to apply:** For one-time startup commands, read `$_SERVER`, `$_ENV`, or `getenv()` at execution time; keep secret values out of source and never include them in command output.