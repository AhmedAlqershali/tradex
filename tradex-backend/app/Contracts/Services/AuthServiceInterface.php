<?php

namespace App\Contracts\Services;

use App\Models\User;

interface AuthServiceInterface
{
    /**
     * Register a client — creates user only.
     */
    public function registerClient(array $data): array;

    /**
     * Register a merchant — creates user + store atomically.
     */
    public function registerMerchant(array $data): array;

    /**
     * Authenticate credentials and return a Sanctum token.
     */
    public function login(string $email, string $password, string $deviceName): array;

    /**
     * Revoke the currently-used token.
     */
    public function logout(User $user): void;

    /**
     * Return the authenticated user's profile.
     */
    public function me(User $user): array;

    // -------------------------------------------------------------------------
    // Password reset (Phase 2 — Step 3)
    // -------------------------------------------------------------------------

    /**
     * Send a password reset link to the given email address.
     * Returns a Password broker status constant string.
     */
    public function sendPasswordResetLink(string $email): string;

    /**
     * Validate a reset token and update the user's password.
     * Returns a Password broker status constant string.
     * On success, all existing Sanctum tokens are revoked.
     */
    public function resetPassword(array $data): string;

    // -------------------------------------------------------------------------
    // Email verification (Phase 2 — Step 3)
    // -------------------------------------------------------------------------

    /**
     * Dispatch a new verification email to the given user.
     */
    public function resendVerificationEmail(User $user): bool;

    /**
     * Mark the user's email as verified and fire the Verified event.
     * The hash comparison is performed by the caller (controller).
     */
    public function markEmailAsVerified(User $user): void;
}
