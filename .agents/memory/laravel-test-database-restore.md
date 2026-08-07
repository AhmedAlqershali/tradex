---
name: Laravel test database restore
description: The imported Laravel test suite can replace the runtime SQLite database during focused feature tests.
---

Focused Laravel feature tests using `RefreshDatabase` can reset the configured SQLite file rather than an isolated test database.

**Why:** The imported app's workflow points directly at its tracked SQLite database, so test migrations and teardown can remove the seeded runtime rows.

**How to apply:** Before verification, preserve the imported database state; after any `RefreshDatabase` test run, restore the tracked SQLite file and re-check seeded accounts and records before reporting results.