---
name: BOM corruption in AI PHP files
description: 8 PHP files in the AI layer had UTF-8 BOM characters that caused PHP fatal errors on namespace declarations.
---

8 files had `\xEF\xBB\xBF` (UTF-8 BOM) prepended, breaking PHP's namespace parser:
- `app/Contracts/Services/AI/AiProviderInterface.php`
- `app/Contracts/Services/AI/AiServiceInterface.php`
- `app/Contracts/Services/AI/AiUsageServiceInterface.php`
- `app/Exceptions/AiNotImplementedException.php`
- `app/Providers/AiServiceProvider.php`
- `app/Services/AI/AiService.php`
- `app/Services/AI/AiUsageService.php`
- `app/Services/AI/Providers/GeminiAiProvider.php`

**Fix:** `sed -i '1s/^\xEF\xBB\xBF//' <file>`

**Why:** Files were likely edited in Windows editors that add BOM. Fatal error message: "Namespace declaration statement has to be the very first statement".

**How to apply:** If PHP gives namespace fatal errors, check for BOM first: `grep -rl $'^\xEF\xBB\xBF' app/`
