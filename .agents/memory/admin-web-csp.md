---
name: Admin web CSP
description: Content Security Policy must distinguish JSON API responses from browser-facing admin pages.
---

API responses can safely use `default-src 'none'`, but that policy blocks the compiled CSS and JavaScript required by the Laravel admin web surface.

**Why:** A global API-only CSP made the login page render as unstyled HTML and produced browser console violations when the admin portal was introduced.

**How to apply:** Keep API responses restrictive; for same-origin admin pages allow only local scripts/styles and the asset sources the views actually use. Add a browser-facing regression assertion when changing the policy.