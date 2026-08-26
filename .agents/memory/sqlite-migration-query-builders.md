---
name: SQLite migration query builders
description: A Laravel query-builder mutability pitfall relevant to data-preserving SQLite table rebuilds.
---

Laravel's query builder is mutable. When a migration needs to validate rows and then count or copy from the same base query, clone the builder before adding validation filters.

**Why:** Reusing a builder after `whereNotIn` can silently apply that filter to a later row count, causing a valid table rebuild to report that it copied more rows than expected.

**How to apply:** Keep an unmodified builder for the authoritative count/copy query, and use `(clone $builder)` for distinct-status or other diagnostic queries.