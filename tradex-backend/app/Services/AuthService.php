<?php

namespace App\Services;

use App\Contracts\Services\AuthServiceInterface;
use App\Contracts\Services\SubscriptionServiceInterface;
use App\Models\Store;
use App\Models\User;
use App\Notifications\QueuedVerifyEmail;
use App\Support\PublicMediaUrl;
use Illuminate\Auth\Events\Verified;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Facades\Storage;
use Throwable;
use Illuminate\Validation\ValidationException;

class AuthService implements AuthServiceInterface
{
    public function __construct(
        private readonly SubscriptionServiceInterface $subscriptionService,
    ) {}

    // -------------------------------------------------------------------------
    // Registration
    // -------------------------------------------------------------------------

    /**
     * Register a client.
     * Creates a user record only — no store.
     *
     * SECURITY: `role` is not in User::$fillable; assign explicitly after fill()
     * to prevent any mass-assignment escalation path.
     */
    public function registerClient(array $data): array
    {
        $user = DB::transaction(function () use ($data) {
            $user = new User();
            $user->fill([
                'name'     => $data['name'],
                'email'    => $data['email'],
                'phone'    => $data['phone'],
                'password' => Hash::make($data['password']),
            ]);
            $user->role   = 'client';
            $user->status = 'active';
            $user->save();

            return $user;
        });

        $verificationEmailSent = $this->sendVerificationNotification($user);

        return [
            'user'                     => $this->userPayload($user),
            'verification_email_sent' => $verificationEmailSent,
        ];
    }

    /**
     * Register a merchant.
     * Creates a user record AND a store atomically inside a DB transaction.
     * If either fails, neither is persisted.
     *
     * SECURITY: `role`, `status`, and `user_id` are set explicitly, never via
     * mass-assignment, to prevent privilege escalation.
     */
    public function registerMerchant(array $data): array
    {
        $registration = DB::transaction(function () use ($data) {
            $user = new User();
            $user->fill([
                'name'     => $data['name'],
                'email'    => $data['email'],
                'phone'    => $data['phone'],
                'password' => Hash::make($data['password']),
            ]);
            $user->role   = 'merchant';
            $user->status = 'active';
            $user->save();

            $store = new Store();
            $store->fill([
                'store_name'  => $data['store_name'],
                'description' => $data['store_description'] ?? null,
            ]);
            $store->user_id = $user->id;
            $store->status  = 'active';
            $store->save();

            $this->subscriptionService->startTrial($user);

            return [
                'user'  => $user,
                'store' => $store,
            ];
        });

        $verificationEmailSent = $this->sendVerificationNotification($registration['user']);

        return [
            'user'                     => $this->userPayload($registration['user']),
            'store'                    => $this->storePayload($registration['store']),
            'verification_email_sent' => $verificationEmailSent,
        ];
    }

    // -------------------------------------------------------------------------
    // Login / Logout / Me
    // -------------------------------------------------------------------------

    /**
     * Authenticate credentials and return a token.
     *
     * SECURITY: banned and inactive users are rejected here (before token
     * issuance), not only in the EnsureUserIsActive middleware. This prevents
     * a banned user from receiving a fresh token on the login endpoint.
     *
     * @throws ValidationException
     */
    public function login(string $email, string $password, string $deviceName): array
    {
        $user = User::where('email', $email)->first();

        if (! $user || ! Hash::check($password, $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['The provided credentials are incorrect.'],
            ]);
        }

        // Block banned / inactive users before issuing any token.
        if ($user->status !== 'active') {
            $message = match ($user->status) {
                'banned'   => 'Your account has been banned. Please contact support.',
                'inactive' => 'Your account is inactive. Please contact support.',
                default    => 'Your account is not active.',
            };

            throw ValidationException::withMessages([
                'email' => [$message],
            ]);
        }

        if (! $user->hasVerifiedEmail()) {
            throw ValidationException::withMessages([
                'email' => ['يرجى تأكيد بريدك الإلكتروني أولًا.'],
            ]);
        }

        // Revoke existing tokens for this device to prevent accumulation
        $user->tokens()->where('name', $deviceName)->delete();

        $token = $user->createToken($deviceName)->plainTextToken;

        return [
            'user'  => $this->userPayload($user),
            'token' => $token,
        ];
    }

    /**
     * Revoke the currently-used token.
     */
    public function logout(User $user): void
    {
        $user->currentAccessToken()->delete();
    }

    /**
     * Return the authenticated user's profile.
     * Merchants also get their store(s) in the payload.
     */
    public function me(User $user): array
    {
        $user = $user->fresh(['stores']);

        $payload = $this->userPayload($user);

        if ($user->isMerchant()) {
            $payload['stores'] = $user->stores->map(fn ($s) => $this->storePayload($s))->values();
        }

        return $payload;
    }

    // -------------------------------------------------------------------------
    // Password reset
    // -------------------------------------------------------------------------

    /**
     * Send a password reset link to the given email address.
     */
    public function sendPasswordResetLink(string $email): string
    {
        return Password::sendResetLink(['email' => $email]);
    }

    /**
     * Reset the user's password using the provided token.
     *
     * @throws ValidationException
     */
    public function resetPassword(array $data): string
    {
        // Note: Laravel's FormRequest::validated() does NOT include
        // 'password_confirmation' in its output (it is consumed by the
        // 'confirmed' validation rule and stripped). Password::reset()
        // only needs the password itself; pass it as both values so the
        // Broker's internal "matches" check is satisfied without relying
        // on a key that may not exist in $data.
        $status = Password::reset(
            [
                'email'                 => $data['email'],
                'password'              => $data['password'],
                'password_confirmation' => $data['password'],
                'token'                 => $data['token'],
            ],
            function (User $user, string $password) {
                $user->password = Hash::make($password);
                $user->save();

                // Revoke all existing tokens so old sessions are invalidated
                $user->tokens()->delete();
            }
        );

        if ($status !== Password::PASSWORD_RESET) {
            throw ValidationException::withMessages([
                'email' => [__($status)],
            ]);
        }

        return $status;
    }

    // -------------------------------------------------------------------------
    // Email verification
    // -------------------------------------------------------------------------

    public function resendVerificationEmail(User $user): bool
    {
        return $this->sendVerificationNotification($user);
    }

    /**
     * Send verification only after registration has committed. Mail transport
     * failures must not turn a persisted account into a misleading 500 error;
     * the authenticated resend endpoint remains available for recovery.
     */
    private function sendVerificationNotification(User $user): bool
    {
        try {
            $user->notify(new QueuedVerifyEmail());

            return true;
        } catch (Throwable $exception) {
            Log::error('Registration verification email could not be queued.', [
                'user_id'   => $user->getKey(),
                'email'     => $user->getEmailForVerification(),
                'exception' => $exception,
            ]);

            return false;
        }
    }

    /**
     * Mark the user's email as verified and fire the Verified event.
     *
     * Hash comparison is done by the controller before calling this method,
     * keeping route concerns out of the service layer.
     */
    public function markEmailAsVerified(User $user): void
    {
        $user->markEmailAsVerified();

        // markEmailAsVerified() does not fire the Verified event internally;
        // we fire it so listeners (analytics, welcome emails, etc.) can hook in.
        event(new Verified($user));
    }

    // -------------------------------------------------------------------------
    // Payload helpers
    // -------------------------------------------------------------------------

    private function userPayload(User $user): array
    {
        $payload = [
            'id'             => $user->id,
            'name'           => $user->name,
            'email'          => $user->email,
            'phone'          => $user->phone,
            'role'           => $user->role,
            'avatar'         => PublicMediaUrl::forPath($user->avatar),
            // Mobile clients use this flag to gate features behind verification
            // (e.g. showing a "verify your email" banner in Flutter).
            'email_verified' => $user->hasVerifiedEmail(),
        ];

        if ($user->isMerchant()) {
            $subscription = $this->subscriptionService->getCurrentForMerchant($user);
            $payload['current_subscription'] = $subscription ? [
                'type'        => $subscription->type,
                'status'      => $subscription->status,
                'is_trial'    => $subscription->isTrial(),
                'is_entitled' => $subscription->isEntitled(),
                'starts_at'   => $subscription->starts_at?->toIso8601String(),
                'ends_at'     => $subscription->ends_at?->toIso8601String(),
            ] : null;
        }

        return $payload;
    }

    private function storePayload(Store $store): array
    {
        return [
            'id'          => $store->id,
            'store_name'  => $store->store_name,
            'description' => $store->description,
            'region'      => $store->region,
            'logo'        => $store->logo,
            'status'      => $store->status,
        ];
    }
}
