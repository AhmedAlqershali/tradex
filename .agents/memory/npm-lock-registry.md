---
name: Portable npm lockfiles
description: Prevent external CI and deployment failures caused by Replit registry URLs embedded in imported npm lockfiles.
---

Imported npm lockfiles may contain `resolved` tarball URLs for Replit's private package firewall rather than the public npm registry. npm's registry setting does not override those lockfile URLs during `npm ci`.

**Why:** An external Render Docker build cannot resolve Replit's private package host, and npm can surface the resulting fetch failure as the generic “Exit handler never called” error.

**How to apply:** Before using an imported lockfile outside Replit, inspect its `resolved` hosts. Normalize them to a reachable registry in the deployment layer or regenerate the lockfile from a public registry without changing dependency versions.