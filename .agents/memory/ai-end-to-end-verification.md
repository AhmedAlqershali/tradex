---
name: AI end-to-end verification
description: AI provider and client must reject blank output and always leave generation controls in a terminal state.
---

AI generation is only complete when both sides validate the result: the provider must reject missing, malformed, or whitespace-only model output, and every Flutter generation surface must clear loading in a `finally` path while surfacing failures.

**Why:** A successful HTTP response can still contain unusable model output, and an uncaught client exception can leave a generation control permanently showing a spinner.

**How to apply:** Preserve these checks when adding AI tools or changing provider response parsing; test provider failures, malformed output, and UI retry behavior.