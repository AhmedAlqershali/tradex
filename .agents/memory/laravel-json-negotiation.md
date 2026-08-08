---
name: Laravel JSON negotiation
description: The imported Laravel API's unauthenticated responses depend on JSON content negotiation.
---

Use `Accept: application/json` when manually probing protected API routes.

**Why:** Without the header, the local Laravel runtime may render the HTML error page and obscure the actual API status; with it, auth failures return the documented JSON response.

**How to apply:** Include the header in curl, smoke checks, and debugging requests to `/api/v1/*`.