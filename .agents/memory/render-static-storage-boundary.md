---
name: Render static storage boundary
description: Non-obvious requirements for serving Laravel public-disk files through the imported Docker PHP router on Render.
---

Committed files under `storage/app/public` are part of the deployable public-disk state. The Docker ignore rules must exclude runtime/private directories without excluding `storage/app/public`; otherwise known fixtures and pre-existing public uploads are absent from the image.

**Why:** The PHP built-in server router resolves symlinks with `realpath()`. A valid `public/storage` request resolves outside `public/`, so a guard that only permits paths physically beneath `public/` sends every symlinked file to Laravel instead of serving it.

**How to apply:** Keep `public/storage` created by `php artisan storage:link --force`, permit only the resolved configured storage target in the router's static-file guard, and verify the exact fixture through the built image and live Render URL after redeploy.