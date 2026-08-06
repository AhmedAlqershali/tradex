---
name: verifyOtp is a no-op by design
description: The backend has no OTP verify endpoint; UserController.verifyOtp must be a no-op; the reset token is validated at resetPassword time.
---

The backend uses Laravel's password-broker flow: `POST /auth/password/forgot` sends an email with a token link; `POST /auth/password/reset` validates the token.

There is no "verify OTP before reset" endpoint. The Flutter UI collects a 4-digit code (which in practice would be the token from the email link) and passes it straight to `resetPassword()`.

**Previous bug:** `verifyOtp()` in `UserController` was calling `resendVerificationEmail()` (a session-protected endpoint), causing 401 crashes during the unauthenticated forgot-password flow.

**Fix applied:** `verifyOtp()` is now a deliberate no-op. The token is validated by the backend when `resetPassword()` is called.

**How to apply:** Do not add API calls to `verifyOtp()`. The UI step is purely cosmetic UX (collecting the token input); validation happens at the next step.
