<?php

namespace App\Http\Controllers\Api\V1;

use App\Contracts\Services\AuthServiceInterface;
use App\Http\Requests\Auth\ClientRegisterRequest;
use App\Http\Requests\Auth\ForgotPasswordRequest;
use App\Http\Requests\Auth\LoginRequest;
use App\Http\Requests\Auth\MerchantRegisterRequest;
use App\Http\Requests\Auth\ResetPasswordRequest;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Password;
use Illuminate\Validation\ValidationException;

class AuthController extends BaseApiController
{
    public function __construct(private readonly AuthServiceInterface $authService) {}

    // -------------------------------------------------------------------------
    // Registration
    // -------------------------------------------------------------------------

    /**
     * POST /api/v1/auth/register/client
     *
     * Fields: name, email, phone, password, password_confirmation
     * Creates: user (role = client)
     */
    public function registerClient(ClientRegisterRequest $request): JsonResponse
    {
        $result = $this->authService->registerClient($request->validated());

        return $this->created($result, 'Client account created successfully.');
    }

    /**
     * POST /api/v1/auth/register/merchant
     *
     * Fields: name, email, phone, password, password_confirmation,
     *         store_name, store_description (optional)
     * Creates: user (role = merchant) + store — atomically
     */
    public function registerMerchant(MerchantRegisterRequest $request): JsonResponse
    {
        $result = $this->authService->registerMerchant($request->validated());

        return $this->created($result, 'Merchant account and store created successfully.');
    }

    // -------------------------------------------------------------------------
    // Login / Logout / Me
    // -------------------------------------------------------------------------

    /**
     * POST /api/v1/auth/login
     */
    public function login(LoginRequest $request): JsonResponse
    {
        try {
            $result = $this->authService->login(
                email:      $request->email,
                password:   $request->password,
                deviceName: $request->input('device_name', 'flutter_app'),
            );

            return $this->success($result, 'Login successful.');
        } catch (ValidationException $e) {
            return $this->validationError($e->errors(), 'Invalid credentials.');
        }
    }

    /**
     * POST /api/v1/auth/logout
     */
    public function logout(Request $request): JsonResponse
    {
        $this->authService->logout($request->user());

        return $this->success(null, 'Logged out successfully.');
    }

    /**
     * GET /api/v1/auth/me
     * Merchants also receive their stores array.
     */
    public function me(Request $request): JsonResponse
    {
        return $this->success(
            $this->authService->me($request->user()),
            'Authenticated user retrieved.'
        );
    }

    // -------------------------------------------------------------------------
    // Password reset (Phase 2 — Step 3)
    // -------------------------------------------------------------------------

    /**
     * POST /api/v1/auth/password/forgot
     *
     * Accepts any email and always returns a generic success message to
     * avoid leaking whether an account exists.
     * Rate limited via throttle:auth (5 req/min/IP).
     */
    public function forgotPassword(ForgotPasswordRequest $request): JsonResponse
    {
        $status = $this->authService->sendPasswordResetLink($request->email);

        // Always respond with 200 so callers cannot enumerate registered emails.
        // RESET_LINK_SENT: email dispatched.  Other statuses: user not found /
        // throttled — we silently absorb them to prevent user-enumeration attacks.
        return $this->success(
            null,
            'If an account with that email exists, a password reset link has been sent.'
        );
    }

    /**
     * POST /api/v1/auth/password/reset
     *
     * Consumes the reset token, updates the password, and revokes all tokens.
     * Rate limited via throttle:auth (5 req/min/IP).
     */
    public function resetPassword(ResetPasswordRequest $request): JsonResponse
    {
        $status = $this->authService->resetPassword($request->validated());

        return match ($status) {
            Password::PASSWORD_RESET => $this->success(
                null,
                'Password has been reset successfully. Please log in with your new password.'
            ),
            Password::INVALID_TOKEN  => $this->error(
                'This password reset token is invalid or has expired.',
                422
            ),
            // Do not disclose whether the supplied email belongs to an
            // account. A reset token is already required, so this response
            // should be indistinguishable from any other invalid token.
            Password::INVALID_USER   => $this->error(
                'This password reset token is invalid or has expired.',
                422
            ),
            Password::RESET_THROTTLED => $this->error(
                'Please wait before requesting another password reset.',
                429
            ),
            default => $this->error('Password reset failed. Please try again.', 422),
        };
    }

    // -------------------------------------------------------------------------
    // Email verification (Phase 2 — Step 3)
    // -------------------------------------------------------------------------

    /**
     * POST /api/v1/auth/email/resend
     *
     * Resends the verification email for the currently authenticated user.
     * Requires: auth:sanctum
     */
    public function resendVerification(Request $request): JsonResponse
    {
        $user = $request->user();

        if ($user->hasVerifiedEmail()) {
            return $this->error('Your email address is already verified.', 422);
        }

        $this->authService->resendVerificationEmail($user);

        return $this->success(null, 'Verification email sent. Please check your inbox.');
    }

    /**
     * GET /api/v1/auth/email/verify/{id}/{hash}
     *
     * Handles the signed verification link that Laravel emails to the user.
     * The 'signed' middleware guarantees the URL has not been tampered with.
     *
     * Mobile flow: the Flutter app registers a deep-link / custom URL scheme
     * that intercepts this URL, calls the API, and reads the JSON response.
     * Web flow: the link opens in a browser; the JSON response is returned.
     */
    public function verifyEmail(Request $request, string $id, string $hash): JsonResponse
    {
        $user = User::find((int) $id);

        if (! $user) {
            return $this->notFound('User not found.');
        }

        // Validate hash — ensures the link belongs to this user's email address.
        if (! hash_equals(sha1($user->getEmailForVerification()), $hash)) {
            return $this->error('Invalid verification link.', 403);
        }

        if ($user->hasVerifiedEmail()) {
            return $this->success(
                ['email_verified' => true],
                'Your email address is already verified.'
            );
        }

        $this->authService->markEmailAsVerified($user);

        return $this->success(
            ['email_verified' => true],
            'Email address verified successfully.'
        );
    }
}
