<?php

namespace Tests\Feature\Auth;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Routing\Middleware\ValidateSignature;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Facades\URL;
use Tests\TestCase;

/**
 * Email verification flow tests.
 *
 * Signed URL tests generate a real signed URL via URL::temporarySignedRoute
 * so the ValidateSignature middleware passes. Tests that specifically check
 * invalid-hash logic disable the signed middleware to isolate controller logic.
 */
class EmailVerificationTest extends TestCase
{
    use RefreshDatabase;

    private function verifyUrl(User $user, ?string $hashOverride = null): string
    {
        $hash = $hashOverride ?? sha1($user->getEmailForVerification());

        $fullUrl = URL::temporarySignedRoute(
            'api.v1.auth.verification.verify',
            now()->addMinutes(60),
            ['id' => $user->id, 'hash' => $hash]
        );

        // Extract path + query for the test HTTP client.
        $parsed = parse_url($fullUrl);

        return $parsed['path'] . (isset($parsed['query']) ? '?' . $parsed['query'] : '');
    }

    private function headers(string $token): array
    {
        return ['Authorization' => "Bearer {$token}", 'Accept' => 'application/json'];
    }

    // =========================================================================
    // GET /api/v1/auth/email/verify/{id}/{hash}
    // =========================================================================

    public function test_unverified_user_can_verify_email(): void
    {
        $user = User::factory()->create(['email_verified_at' => null]);

        $this->assertNull($user->email_verified_at);

        $this->getJson($this->verifyUrl($user))
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.email_verified', true);

        $this->assertNotNull($user->fresh()->email_verified_at);
    }

    public function test_already_verified_user_gets_success_with_flag(): void
    {
        $user = User::factory()->create(['email_verified_at' => now()]);

        $this->getJson($this->verifyUrl($user))
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.email_verified', true);
    }

    public function test_invalid_hash_returns_403(): void
    {
        $user = User::factory()->create(['email_verified_at' => null]);

        // Bypass the signed middleware to test the hash comparison logic.
        $this->withoutMiddleware(ValidateSignature::class)
            ->getJson("/api/v1/auth/email/verify/{$user->id}/badhash")
            ->assertStatus(403)
            ->assertJsonPath('success', false);
    }

    public function test_nonexistent_user_returns_404(): void
    {
        $user = User::factory()->create(['email_verified_at' => null]);

        // Use a valid-looking signed URL but with a non-existent user ID.
        $this->withoutMiddleware(ValidateSignature::class)
            ->getJson('/api/v1/auth/email/verify/99999/somehash')
            ->assertNotFound()
            ->assertJsonPath('success', false);
    }

    public function test_tampered_signature_is_rejected(): void
    {
        $user = User::factory()->create(['email_verified_at' => null]);

        // Build the valid URL then tamper with the signature parameter.
        $url     = $this->verifyUrl($user);
        $tampered = $url . '&extra=1'; // invalidates the signature

        $this->getJson($tampered)
            ->assertStatus(403); // ValidateSignature returns 403 on failure
    }

    public function test_verify_response_has_standard_envelope(): void
    {
        $user = User::factory()->create(['email_verified_at' => null]);

        $this->getJson($this->verifyUrl($user))
            ->assertOk()
            ->assertJsonStructure(['success', 'message', 'data' => ['email_verified']]);
    }

    // =========================================================================
    // POST /api/v1/auth/email/resend
    // =========================================================================

    public function test_unverified_user_can_request_resend(): void
    {
        Notification::fake();

        $user  = User::factory()->create(['email_verified_at' => null]);
        $token = $user->createToken('test')->plainTextToken;

        $this->postJson('/api/v1/auth/email/resend', [], $this->headers($token))
            ->assertOk()
            ->assertJsonPath('success', true);
    }

    public function test_already_verified_user_gets_error_on_resend(): void
    {
        $user  = User::factory()->create(['email_verified_at' => now()]);
        $token = $user->createToken('test')->plainTextToken;

        $this->postJson('/api/v1/auth/email/resend', [], $this->headers($token))
            ->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_resend_requires_authentication(): void
    {
        $this->postJson('/api/v1/auth/email/resend', [])
            ->assertStatus(401)
            ->assertJsonPath('success', false);
    }
}
