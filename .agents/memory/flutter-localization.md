---
name: Flutter localization
description: The app-wide Arabic/English localization and persistence decision for future Flutter UI work.
---

Use the app-level localization delegate and locale controller for all new Flutter strings and language changes. Keep the selected language in the existing local preferences store so the root app can restore it before navigation starts.

**Why:** Profile Settings exposed that the imported Flutter app had hardcoded Arabic UI and no working app-level locale state. A single root locale source updates direction, navigation labels, and screens together without recreating the BLoC providers.

**How to apply:** Add new translations to the central localization map/delegate and read the current localized strings from `BuildContext`; update the shared locale controller rather than adding screen-local translation maps or persistence keys.