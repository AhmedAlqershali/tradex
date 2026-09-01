# Email Verification Implementation - Test Plan & Verification Steps

## Overview

This document provides step-by-step verification procedures for the email verification system implementation. Tests are organized by type: code-level (can run now), integration-level (requires running services), and end-to-end (requires deployed system).

---

## CODE-LEVEL VERIFICATION (Executable Now - No Runtime Environment)

### Test 1: Dart Code Structure Verification

**Objective**: Verify Flutter code compiles and has no syntax errors

**Steps**:
```bash
# From /workspaces/tradex/flutter_app
dart analyze lib/presentation/blocs/auth/auth_state.dart
dart analyze lib/presentation/blocs/auth/auth_bloc.dart
dart analyze lib/screens/auth/register_screen.dart
dart analyze lib/screens/auth/email_verification_screen.dart
dart analyze lib/core/api/api_constants.dart
```

**Expected Results**:
- ✅ No syntax errors
- ✅ No type errors
- ✅ All imports resolve
- ✅ All class definitions valid

**Verification Code**:
```bash
# Quick verification: Check imports in key files
grep -n "import.*AuthAwaitingEmailVerification\|class AuthAwaitingEmailVerification" lib/presentation/blocs/auth/auth_state.dart
grep -n "emit(AuthAwaitingEmailVerification" lib/presentation/blocs/auth/auth_bloc.dart
grep -n "EmailVerificationScreen" lib/screens/auth/register_screen.dart
```

---

### Test 2: Auth State Machine Integrity

**Objective**: Verify new state is properly integrated into auth state hierarchy

**Verification Steps**:
```dart
// In the auth_state.dart file:
// 1. AuthAwaitingEmailVerification extends AuthState ✓
// 2. Has required properties: user (AppUser), role (AppType) ✓
// 3. Implements props getter for Equatable ✓
// 4. Has copyWith or equivalent (implied from user.copyWith usage) ✓

// Expected file structure:
class AuthAwaitingEmailVerification extends AuthState {
  const AuthAwaitingEmailVerification({required this.user, required this.role});
  final AppUser user;
  final AppType role;
  List<Object?> get props => [user, role];
}
```

**Proof**:
```bash
grep -A 5 "class AuthAwaitingEmailVerification" lib/presentation/blocs/auth/auth_state.dart
```

---

### Test 3: Auth BLoC Registration Handler

**Objective**: Verify registration flow emits new state instead of old state

**Verification Steps**:

**OLD CODE (SHOULD NOT EXIST)**:
```dart
if (!isClosed) emit(AuthAuthenticated(user: user));  // ❌ MUST NOT BE HERE
```

**NEW CODE (MUST EXIST)**:
```dart
if (!isClosed) emit(AuthAwaitingEmailVerification(user: user, role: event.role));  // ✓ CORRECT
```

**Proof**:
```bash
grep -A 3 "emit(AuthAwaitingEmailVerification" lib/presentation/blocs/auth/auth_bloc.dart | head -5
```

---

### Test 4: RegisterScreen BlocListener Handler

**Objective**: Verify register screen navigates to EmailVerificationScreen on new state

**Verification Steps**:

Check that listener has:
```dart
if (state is AuthAwaitingEmailVerification) {
  // Navigate to EmailVerificationScreen
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => EmailVerificationScreen(
        user: state.user,
        role: state.role,
        onVerificationSuccess: (verifiedUser) { ... }
      ),
    ),
  );
}
```

**Proof**:
```bash
grep -B 2 -A 10 "if (state is AuthAwaitingEmailVerification)" lib/screens/auth/register_screen.dart | head -15
```

---

### Test 5: API Constants Definition

**Objective**: Verify resend endpoint constant is defined

**Verification Steps**:

Should exist:
```dart
static const String resendVerificationUnauthenticated = '/auth/email/resend-unauthenticated';
```

**Proof**:
```bash
grep "resendVerificationUnauthenticated" lib/core/api/api_constants.dart
```

---

### Test 6: Backend PHP Method Signature

**Objective**: Verify backend endpoint is properly defined

**Verification Steps**:

Should have method:
```php
public function resendVerificationUnauthenticated(Request $request): JsonResponse
{
    $request->validate(['email' => 'required|email:rfc,dns']);
    $user = User::where('email', $request->email)->first();
    if (!$user) {
        return $this->success(null, 'If an account with that email exists...');
    }
    if ($user->hasVerifiedEmail()) {
        return $this->success(['email_verified' => true], '...');
    }
    if (!$this->authService->resendVerificationEmail($user)) {
        return $this->error('...', 503);
    }
    return $this->success(null, 'Verification email sent...');
}
```

**Proof**:
```bash
grep -A 20 "function resendVerificationUnauthenticated" tradex-backend/app/Http/Controllers/Api/V1/AuthController.php
```

---

### Test 7: Backend Route Definition

**Objective**: Verify route is properly registered with rate limiting

**Verification Steps**:

Should have:
```php
Route::middleware('throttle:auth')->group(function () {
    Route::post('/email/resend-unauthenticated', [AuthController::class, 'resendVerificationUnauthenticated'])->name('verification.resend-unauthenticated');
});
```

**Proof**:
```bash
grep -B 2 -A 1 "resend-unauthenticated" tradex-backend/routes/api.php
```

---

## INTEGRATION VERIFICATION (Requires Running Environment)

### Test 8: Flutter to Backend API Compatibility

**Objective**: Verify Flutter and Laravel endpoint contract match

**Setup**:
1. Start Laravel backend on localhost:8000
2. Configure Flutter app to use localhost:8000

**Test Steps**:
```bash
# 1. Test registration returns user without token
curl -X POST http://localhost:8000/api/v1/auth/register/client \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "phone": "+201234567890",
    "password": "Password123!",
    "password_confirmation": "Password123!"
  }'

# Expected response:
# {
#   "data": { "id": 1, "email": "test@example.com", ... },
#   "message": "..."
# }
# NO token field (token should only be issued after verification)

# 2. Test resend endpoint
curl -X POST http://localhost:8000/api/v1/auth/email/resend-unauthenticated \
  -H "Content-Type: application/json" \
  -d '{ "email": "test@example.com" }'

# Expected response:
# {
#   "data": null,
#   "message": "If an account with that email exists, a verification email has been sent.",
#   "success": true
# }
```

---

### Test 9: Deep Link Parser Recognition

**Objective**: Verify deep link parser recognizes email verification URLs

**Test Flutter Code**:
```dart
// Test EmailVerificationLinkParser
const testUrl = 'https://app.tradex.com/auth/email/verify/123/abc123hash?signature=sig123&expires=1234567890';
final parsed = EmailVerificationLinkParser.parse(testUrl);

// Expected:
assert(parsed != null);
assert(parsed!.userId == '123');
assert(parsed!.hash == 'abc123hash');
assert(parsed!.signature == 'sig123');
assert(parsed!.expires == '1234567890');

// Test password reset still works
const resetUrl = 'https://app.tradex.com/auth/password/reset?email=user@example.com&token=abc123';
final resetParsed = PasswordResetLinkParser.parse(resetUrl);
assert(resetParsed != null);  // Should still work
```

---

### Test 10: EmailVerificationScreen Rendering

**Objective**: Verify screen renders without errors

**Test Steps** (in Flutter app):
1. Register user (navigate to EmailVerificationScreen manually if needed)
2. Verify screen shows:
   - "تحقق من بريدك الإلكتروني" (Check your email) - Arabic
   - Email address display
   - "إعادة إرسال رمز التحقق" (Resend verification email) button
   - Loading indicator when verifying
   - Error message area (hidden initially)

**Proof Points**:
- ✅ Screen builds without crashes
- ✅ All text is in Arabic (RTL)
- ✅ Buttons are clickable
- ✅ Loading states work

---

## END-TO-END VERIFICATION (Full System Test)

### Test 11: Complete Registration → Verification Flow

**Prerequisites**:
- ✅ Flutter app built and running
- ✅ Laravel backend deployed
- ✅ SMTP email configured
- ✅ Queue worker running (`php artisan queue:work`)

**Test Steps**:

1. **Open App & Navigate to Registration**
   ```
   Launch app → Select "Client" or "Merchant"
   ```

2. **Register with Test Email**
   ```
   Name: Test User
   Email: test+<timestamp>@example.com  (use unique email each time)
   Phone: +201234567890
   Password: TestPass123!
   ```

3. **Verify Navigation After Registration**
   ```
   Expected: EmailVerificationScreen appears
   Not expected: CompleteProfileClientScreen appears
   ```

4. **Check Email Received**
   ```
   Open email client
   Wait up to 30 seconds for email to arrive
   Email subject: "Verify Email Address" (or similar)
   Email body: Contains link to /auth/email/verify/{id}/{hash}?signature=...&expires=...
   ```

5. **Test Resend Button**
   ```
   Click "إعادة إرسال رمز التحقق" (Resend) button
   Wait for loading spinner
   Verify API call succeeds (no error shown)
   Wait for new email to arrive
   ```

6. **Click Verification Link**
   ```
   From email, click verification link
   
   Option A (Mobile): App intercepts deep link
   - EmailVerificationScreen shows loading
   - DeepLinkService.onEmailVerificationLink callback triggered
   - EmailVerificationScreen calls GET /api/v1/auth/email/verify/{id}/{hash}?...
   - Success: "تم التحقق من بريدك الإلكتروني" (Email verified successfully)
   - After 1.5 seconds: Navigate to profile completion screen
   
   Option B (Browser): Shows JSON response
   - { "data": { "email_verified": true }, "message": "..." }
   ```

7. **Complete Profile**
   ```
   After verification callback, user sees CompleteProfileClientScreen
   Complete profile and proceed
   ```

8. **Test Login with Verified Email**
   ```
   Logout
   Login with same email
   Should succeed (user has verified email)
   ```

---

### Test 12: Error Handling

**Test 12a: Invalid/Expired Verification Link**
```
Modify verification link in email:
- Change {id} to invalid ID
- Change {hash} to wrong hash
- Wait 60 minutes (link expires)

Expected: EmailVerificationScreen shows error
"رابط التحقق غير صالح" (Invalid verification link)
User can click Resend to get new link
```

**Test 12b: Network Error During Verification**
```
Turn off network connection
Click verification link
Wait for timeout

Expected: EmailVerificationScreen shows error
"خطأ في الاتصال" (Connection error)
Button to "محاولة مرة أخرى" (Retry)
```

**Test 12c: Email Not Found**
```
Delete user from database
Try to verify existing verification link

Expected: API returns 404 "User not found"
EmailVerificationScreen shows error
User can Resend to different email (will fail - no user)
```

---

### Test 13: Rate Limiting

**Objective**: Verify rate limit on resend endpoint

**Test Steps**:
```bash
# Make 6 rapid requests to resend endpoint (limit is 5/min/IP)
for i in {1..6}; do
  curl -X POST http://localhost:8000/api/v1/auth/email/resend-unauthenticated \
    -H "Content-Type: application/json" \
    -d '{"email": "test@example.com"}' \
    -w "\nRequest $i: %{http_code}\n"
  sleep 0.1
done

# Expected:
# Requests 1-5: 200 OK
# Request 6: 429 Too Many Requests (rate limited)
# After 60 seconds: Can make requests again
```

---

### Test 14: User Enumeration Protection

**Objective**: Verify resend endpoint doesn't leak user existence

**Test Steps**:
```bash
# Test with existing user
curl -X POST http://localhost:8000/api/v1/auth/email/resend-unauthenticated \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com"}'

# Response A: "If an account with that email exists, a verification email has been sent."

# Test with non-existing user
curl -X POST http://localhost:8000/api/v1/auth/email/resend-unauthenticated \
  -H "Content-Type: application/json" \
  -d '{"email": "nonexistent@example.com"}'

# Response B: "If an account with that email exists, a verification email has been sent."

# Expected: Response A === Response B (same message, no difference)
```

---

### Test 15: Deep Link Security

**Objective**: Verify signed URL validation prevents tampering

**Test Steps**:

1. **Get valid link from email**
   ```
   Original: /auth/email/verify/123/abc123hash?signature=sig123&expires=1234567890
   ```

2. **Modify the link**
   ```
   Modified (change ID): /auth/email/verify/999/abc123hash?signature=sig123&expires=1234567890
   ```

3. **Click modified link in app**
   ```
   Expected: Backend rejects (signature validation fails)
   Error: 403 Forbidden "Invalid verification link"
   ```

4. **Verify signature generation uses Laravel's signed URL middleware**
   ```
   # In routes/api.php:
   Route::get('/email/verify/{id}/{hash}', [...])
     ->middleware('signed')  # ← Validates signature
   ```

---

### Test 16: Already Verified User

**Objective**: Verify behavior when user clicks verification link twice

**Test Steps**:

1. **Register and verify email once**
   ```
   Follow Test 11 through step 6
   ```

2. **Click same verification link again**
   ```
   Click link again from email (or browser history)
   ```

3. **Expected behavior**:
   ```
   Backend returns: { "email_verified": true, "message": "Your email address is already verified." }
   Frontend shows: "بريدك الإلكتروني مُتحقق منه بالفعل" (Email already verified)
   No error, just informational message
   ```

---

### Test 17: Merchant vs Client Navigation

**Objective**: Verify correct profile completion screen for each role

**Test Steps**:

**For Merchant**:
1. Register as merchant
2. Navigate to EmailVerificationScreen
3. Verify email
4. Expected: Navigates to CompleteProfileMerchantScreen
   ```dart
   CompleteProfileMerchantScreen(type: AppType.merchant)
   ```

**For Client**:
1. Register as client
2. Navigate to EmailVerificationScreen
3. Verify email
4. Expected: Navigates to CompleteProfileClientScreen

---

## VERIFICATION CHECKLIST

### ✅ Code-Level (Can verify now)
- [ ] AuthAwaitingEmailVerification state defined
- [ ] auth_bloc.dart emits new state on registration
- [ ] register_screen.dart listens for new state
- [ ] register_screen.dart navigates to EmailVerificationScreen
- [ ] EmailVerificationScreen component created
- [ ] API constant defined for resend endpoint
- [ ] Backend method resendVerificationUnauthenticated exists
- [ ] Backend route defined with rate limiting
- [ ] Deep link parser recognizes email verification URLs
- [ ] DeepLinkService calls email verification handler first

### ✅ Integration-Level (Requires running services)
- [ ] Flutter builds without errors
- [ ] Flutter app shows EmailVerificationScreen after registration
- [ ] Resend button calls correct endpoint
- [ ] Deep link listener receives callbacks
- [ ] Backend accepts POST /api/v1/auth/email/resend-unauthenticated
- [ ] Backend validates email format
- [ ] Backend protects against user enumeration

### ✅ End-to-End (Requires deployed system)
- [ ] Register → EmailVerificationScreen flow works
- [ ] Email received with verification link
- [ ] Resend email works
- [ ] Click email link → app intercepts
- [ ] Verification succeeds → navigate to profile completion
- [ ] Login succeeds after verification
- [ ] Login fails before verification
- [ ] Rate limiting works (>5 requests in 60s blocked)
- [ ] Invalid links rejected (403)
- [ ] Already verified users see appropriate message
- [ ] Merchant/Client navigation correct

---

## Files to Validate

### Flutter Files

**File**: [auth_state.dart](lib/presentation/blocs/auth/auth_state.dart)
- Line: ~65 - `class AuthAwaitingEmailVerification`
- Requires: `final AppUser user`, `final AppType role`
- Requires: `List<Object?> get props => [user, role]`

**File**: [auth_bloc.dart](lib/presentation/blocs/auth/auth_bloc.dart)
- Line: ~61 - Should emit `AuthAwaitingEmailVerification` NOT `AuthAuthenticated`
- Requires: `emit(AuthAwaitingEmailVerification(user: user, role: event.role))`

**File**: [register_screen.dart](lib/screens/auth/register_screen.dart)
- Line: ~154 - Import `EmailVerificationScreen`
- Line: ~156 - Check for `if (state is AuthAwaitingEmailVerification)`
- Requires: Navigate to `EmailVerificationScreen` with `onVerificationSuccess` callback

**File**: [email_verification_screen.dart](lib/screens/auth/email_verification_screen.dart)
- Should be created (620+ lines)
- Must listen to `DeepLinkService.instance.onEmailVerificationLink`
- Must have resend button calling `ApiConstants.resendVerificationUnauthenticated`

**File**: [api_constants.dart](lib/core/api/api_constants.dart)
- Line: Should have `resendVerificationUnauthenticated = '/auth/email/resend-unauthenticated'`

**File**: [password_reset_link_service.dart](lib/core/services/password_reset_link_service.dart)
- Should have `EmailVerificationLinkParser` class
- Should have `onEmailVerificationLink` callback
- Deep link handler should try email verification BEFORE password reset

### Laravel Backend Files

**File**: [AuthController.php](app/Http/Controllers/Api/V1/AuthController.php)
- Should have `resendVerificationUnauthenticated()` method
- Must validate email input
- Must look up user by email
- Must protect against user enumeration

**File**: [routes/api.php](routes/api.php)
- Should have route: `POST /api/v1/auth/email/resend-unauthenticated`
- Must be wrapped in `Route::middleware('throttle:auth')`
- Must point to `[AuthController::class, 'resendVerificationUnauthenticated']`

---

## Known Limitations

⚠️ **These items cannot be tested from Codespaces**:

1. **Email Delivery**: Cannot verify SMTP actually sends emails
   - Requires: Working SMTP server configuration in render.yaml
   - Test manually: Check email inbox after registration

2. **Queue Processing**: Cannot verify queue worker is running
   - Requires: Running `php artisan queue:work database` on Render
   - Test manually: Check `failed_jobs` table for failures

3. **Deep Link Interception**: Cannot test on Codespaces
   - Requires: iOS/Android device or simulator
   - Requires: App built with deep link scheme configured
   - Test manually: Click verification email on actual device

4. **End-to-End Flow**: Cannot verify complete flow
   - Requires: All 3 items above
   - Test manually: Full registration → verification → login flow

---

## Success Criteria

✅ **Minimum**: All code-level verification tests pass
✅ **Expected**: Code + Integration tests pass
✅ **Production**: All tests including end-to-end pass

Implementation is considered **COMPLETE** when:
- All code structures match specifications
- All API endpoints exist and have correct signatures
- All navigation paths connect correctly
- Error handling is implemented for all scenarios
- Rate limiting and security measures are in place
