---
name: Admin category multipart updates
description: Laravel category updates with optional images must use POST plus the standard _method override from the Flutter client.
---

Laravel's category update route is declared as PUT, but PHP does not reliably populate multipart form fields for native PUT requests. The Flutter service sends multipart updates as POST with `_method=PUT`.

**Why:** Sending a native multipart PUT can drop the name, status, or image before Laravel validation/controller handling.

**How to apply:** Preserve the method override for any future Flutter category update that includes an image; plain JSON updates may continue using PUT where the endpoint accepts them.