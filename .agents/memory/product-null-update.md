---
name: Product nullable updates
description: Explicit null values in merchant product updates must survive both service and repository payload filtering.
---

Merchant product updates must distinguish omitted fields from explicitly nullable fields. Build the update payload from keys present in validated input and pass it through without removing nulls, so category and description can be cleared while omitted fields remain unchanged.

**Why:** Filtering nulls in either the service or repository silently turns an intentional clear into a no-op.

**How to apply:** Preserve explicit nulls for nullable product fields through the Service → Repository → Eloquent update path, and cover both clear and omission behavior with a focused feature test.