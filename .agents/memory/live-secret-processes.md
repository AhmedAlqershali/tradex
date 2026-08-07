---
name: Live secret process loading
description: Newly added Replit Secrets are available to new processes, not already-running workflows.
---

Replit Secrets are injected into processes when they start. An already-running Laravel workflow may not see a secret added later; a separate process can verify it without changing the configured workflow.

**Why:** Live Gemini verification initially saw the secret in the shell but not in the existing server process.

**How to apply:** After adding a secret, use a newly started verification process or restart the workflow only when permitted; never copy the value into project files.