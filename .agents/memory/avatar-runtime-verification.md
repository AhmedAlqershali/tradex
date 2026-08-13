---
name: Avatar runtime verification
description: The avatar source contract is testable, but the real upload URL and hosted file response require an authenticated device runtime trace.
---

The avatar path can be fully correct in Flutter and Laravel source tests while the immediate display failure remains unlocated until one real upload records the response URL and the final image request.

**Why:** Source tests use synthetic URLs and fake storage; they do not prove the APK received `data.avatar`, that the production file exists, or that the device can fetch the exact returned URL.

**How to apply:** For an existing account only, capture redacted status/host/path, `data.avatar`, `AppUser.photoPath`, notifier value, final `NetworkImage` URL, and the image request status/content type. Do not create accounts, request tokens, or expose credentials.