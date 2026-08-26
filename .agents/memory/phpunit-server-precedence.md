---
name: PHPUnit server-variable precedence
description: Imported Replit runtime variables can override PHPUnit env settings when Laravel resolves configuration.
---

In this imported Laravel project, PHPUnit `<env>` settings are visible through `getenv()` and `$_ENV`, but Replit-injected `$_SERVER` values take precedence in Laravel's environment repository. Test-only values that must override shared runtime settings should be declared as PHPUnit `<server>` variables.

**Why:** The shared runtime supplied file sessions, file cache, and the tracked SQLite path to PHPUnit despite the XML `<env>` declarations, causing the root request to fail while the test expected array sessions/cache and an in-memory database.

**How to apply:** When PHPUnit or a standalone Laravel bootstrap behaves differently from its requested environment in Replit, inspect sanitized `$_SERVER`, `$_ENV`, and `getenv()` values before changing application code or creating environment files; set test-process `$_SERVER` overrides when isolation is required.