<?php

namespace App\Services;

use App\Contracts\Services\AuthServiceInterface;
use App\Contracts\Services\GoogleTokenVerifierInterface;
use App\Exceptions\GoogleAuthenticationException;
use App\Models\Store;
use App\Models\User;
use App\Contracts\Services\SubscriptionServiceInterface;
use Illuminate\Auth\Events\Verified;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class AuthService implements AuthServiceInterface
{
    public function __construct(
        private readonly SubscriptionServiceInterface $subscriptionService,
        private readonly GoogleTokenVerifierInterface $googleTokenVerifier,
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

        $token = $user->createToken($data['device_name'] ?? 'flutter_app')->plainTextToken;

        return [
            'user'  => $this->userPayload($user),
            'token' => $token,
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

            $token = $user->createToken($data['device_name'] ?? 'flutter_app')->plainTextToken;

            return [
                'user'  => $user,
                'store' => $store,
                'token' => $token,
            ];
        });

        return [
            'user'  => $this->userPayload($registration['user']),
            'store' => $this->storePayload($registration['store']),
            'token' => $registration['token'],
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

        // Revoke existing tokens for this device to prevent accumulation
        $user->tokens()->where('name', $deviceName)->delete();

        $token = $user->createToken($deviceName)->plainTextToken;

        return [
            'user'  => $this->userPayload($user),
            'token' => $token,
        ];
    }

    /**
     * Authenticate a verified Google identity.
     *
     * Google can only create or link a normal client account. Existing
     * password accounts are linked by verified email, while a Google subject
     * can never be moved between users.
     *
     * @throws GoogleAuthenticationException|ValidationException
     */
    public function loginWithGoogle(string $credential, string $deviceName): array
    {
        $identity = $this->googleTokenVerifier->verify($credential);
        $email = strtolower(trim($identity['email']));

        $user = DB::transaction(function () use ($identity, $email) {
            $linkedUser = User::where('google_id', $identity['sub'])
                ->lockForUpdate()
                ->first();

            if ($linkedUser) {
                if (strcasecmp($linkedUser->email, $email) !== 0) {
                    throw new GoogleAuthenticationException(
                        'This Google account is linked to a different email address.',
                        409
                    );
                }

                return $this->ensureGoogleUserCanAuthenticate($linkedUser);
            }

            // Email is verified by Google, so link an existing non-admin
            // Tradex account instead of creating a duplicate user.
            $user = User::whereRaw('LOWER(email) = ?', [$email])
                ->lockForUpdate()
                ->first();

            if ($user) {
                $this->ensureGoogleUserCanAuthenticate($user);

                if ($user->google_id !== null && $user->google_id !== $identity['sub']) {
                    throw new GoogleAuthenticationException(
                        'This Tradex account is linked to a different Google account.',
                        409
                    );
                }

                if ($user->google_id === null) {
                    $user->google_id = $identity['sub'];
                    $user->email_verified_at ??= now();
                    $user->save();
                }

                return $user->fresh();
            }

            $newUser = new User();
            $newUser->fill([
                'name'     => $identity['name'] ?? Str::before($email, '@'),
                'email'    => $email,
                // Keep the existing non-null password schema intact. The
                // random value is never returned or used for Google login.
                'password' => Hash::make(Str::random(64)),
            ]);
            $newUser->google_id = $identity['sub'];
            $newUser->role = 'client';
            $newUser->status = 'active';
            $newUser->email_verified_at = now();
            $newUser->save();

            return $newUser;
        });

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

    public function resendVerificationEmail(User $user): void
    {
        $user->sendEmailVerificationNotification();
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
        return [
            'id'             => $user->id,
            'name'           => $user->name,
            'email'          => $user->email,
            'phone'          => $user->phone,
            'role'           => $user->role,
            'avatar'         => $user->avatar
                ? Storage::disk('public')->url($user->avatar)
                : null,
            // Mobile clients use this flag to gate features behind verification
            // (e.g. showing a "verify your email" banner in Flutter).
            'email_verified' => $user->hasVerifiedEmail(),
        ];
    }

    private function ensureGoogleUserCanAuthenticate(User $user): User
    {
        if ($user->role === 'admin') {
            throw new GoogleAuthenticationException(
                'Admin accounts cannot authenticate with Google.',
                403
            );
        }

        if ($user->status !== 'active') {
            $message = match ($user->status) {
                'banned'   => 'Your account has been banned. Please contact support.',
                'inactive' => 'Your account is inactive. Please contact support.',
                default    => 'Your account is not active.',
            };

            throw ValidationException::withMessages([
                'credential' => [$message],
            ]);
        }

        return $user;
    }

    private function storePayload(Store $store): array
    {
        return [
            'id'          => $store->id,
            'store_name'  => $store->store_name,
            'description' => $store->description,
            'logo'        => $store->logo,
            'status'      => $store->status,
        ];
    }
}
