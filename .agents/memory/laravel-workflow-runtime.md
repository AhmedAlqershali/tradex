---
name: Laravel workflow runtime
description: Replit workflow requirements for this imported Laravel app's local runtime.
---

The imported Laravel app has a production-oriented `.env.example`, while Replit supplies local SQLite and runtime settings externally. The long-running workflow must explicitly export the SQLite database path, file cache/session, and log mail settings, then serve from Laravel's `public/` document root.

**Why:** The default imported process inherited MySQL/database-cache settings and the framework's internal server wrapper looked for a root-level `index.php`, causing live requests to fail even though PHPUnit passed.

**How to apply:** Keep the existing Laravel architecture and use the established `Start application` workflow command with explicit local runtime exports and `php -S ... -t public public/index.php`. Do not embed secrets in workflow commands; let the ignored local `.env` provide `APP_KEY`.