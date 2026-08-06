---
name: AI interface mismatches
description: Three AI contracts had stale method signatures that didn't match concrete implementations — pattern and fix for this project.
---

Three contracts were out of sync with their implementations (BOM corruption made the files hard to detect earlier):

- `AiProviderInterface` declared `generateResponse/streamResponse` but all services called `complete(systemPrompt, userPrompt, options)`. Fixed to declare `complete()`.
- `AiServiceInterface` declared `ask(string, int, array)` but services implemented `generate(array)`. Fixed to declare `generate()`.
- `AiUsageServiceInterface` declared `hasAvailableQuota/logUsage` but services called `checkLimit/record/recordRequest/getUsageSummary`. Fixed to declare real methods.

**Why:** The project went through at least two refactoring passes (OpenAI → Gemini, old usage tracking → new). Interfaces weren't updated in lockstep with implementations.

**How to apply:** When adding or changing AI service methods, update the contract in `app/Contracts/Services/AI/` first, then the implementation. Run `php artisan test` — the PHP fatal errors from mismatched interfaces appear immediately.
