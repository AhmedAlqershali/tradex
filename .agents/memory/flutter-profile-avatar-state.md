---
name: Flutter profile avatar state
description: The canonical Flutter state source and rendering contract for authenticated profile avatars.
---

Profile screens should render identity fields, including the avatar, from `UserController.currentUserNotifier`. Profile refreshes and mutations update that notifier; a `UserBloc` snapshot may still be initial or stale when the screen is first shown.

**Why:** Login, registration, session restoration, and edit-profile flows update the singleton user controller directly. Listening only to the profile bloc made the UI keep showing its placeholder until a separate refresh succeeded.

**How to apply:** Keep server-avatar validation in `AppUser` and use a network image only for validated absolute or `/storage/` server paths. Treat picker file paths as transient and use the local asset only for null, empty, invalid, or failed network images. Do not add cache busting unless the server reuses the same URL for changed image bytes.

Profile edits can issue an avatar upload followed by a text-profile update; the upload response must remain authoritative for the avatar when merging those results.

**Why:** A second profile response can be stale or omit the just-uploaded avatar, causing the notifier to fall back to the local placeholder even though the upload succeeded.

**How to apply:** Preserve the upload's server photo URL through any subsequent profile mutation before publishing the final `currentUserNotifier` value.