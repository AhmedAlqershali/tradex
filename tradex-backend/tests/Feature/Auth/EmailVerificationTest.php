<?php

namespace Tests\Feature\Auth;

use App\Models\User;
use App\Notifications\QueuedVerifyEmail;
use Illuminate\Auth\Notifications\VerifyEmail;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Request;
use Illuminate\Notifications\SendQueuedNotifications;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Facades\Queue;
use Illuminate\Support\Facades\URL;
use RuntimeException;
use Tests\TestCase;

class EmailVerificationTest extends TestCase
{
    use RefreshDatabase;

    private function verifyUrl(User $user, ?string $hash = null): string
    {
        $url = URL::temporarySignedRoute(
            'api.v1.auth.verification.verify',
            now()->addMinutes(60),
            [
                'id' => $user->id,
                'hash' => $hash ?? sha1($user->getEmailForVerification()),
            ]
        );
        $parts = parse_url($url);

        return $parts['path'].'?'.$parts['query'];
    }

    public function test_registration_creates_one_unverified_user_without_dispatching_laravel_notification(): void
    {
        Queue::fake();

        $response = $this->postJson('/api/v1/auth/register/client', [
            'name' => 'New Client',
            'email' => 'new-client@example.com',
            'phone' => '0501234567',
            'password' => 'Password123!',
            'password_confirmation' => 'Password123!',
        ]);

        $response->assertCreated()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.verification_email_sent', false)
            ->assertJsonPath('data.firebase_verification_required', true)
            ->assertJsonMissingPath('data.token');

        $user = User::where('email', 'new-client@example.com')->firstOrFail();
        $this->assertNull($user->email_verified_at);
        $this->assertSame(1, User::where('email', $user->email)->count());

        Queue::assertNothingPushed();
    }

    public function test_duplicate_email_returns_validation_error(): void
    {
        User::factory()->create(['email' => 'duplicate@example.com']);

        $this->postJson('/api/v1/auth/register/client', [
            'name' => 'Duplicate',
            'email' => 'duplicate@example.com',
            'phone' => '0501234567',
            'password' => 'Password123!',
            'password_confirmation' => 'Password123!',
        ])->assertStatus(422)
            ->assertJsonPath('success', false)
            ->assertJsonPath('errors.email.0', 'This email address is already registered.');
    }

    public function test_firebase_registration_keeps_account_unverified(): void
    {
        $response = $this->postJson('/api/v1/auth/register/client', [
            'name' => 'Queue Failure',
            'email' => 'queue-failure@example.com',
            'phone' => '0501234567',
            'password' => 'Password123!',
            'password_confirmation' => 'Password123!',
        ]);

        $response->assertCreated()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.verification_email_sent', false)
            ->assertJsonPath('data.firebase_verification_required', true);

        $this->assertDatabaseHas('users', [
            'email' => 'queue-failure@example.com',
            'email_verified_at' => null,
        ]);
    }

    public function test_invalid_firebase_id_token_cannot_verify_email(): void
    {
        $user = User::factory()->unverified()->create();

        $this->postJson('/api/v1/auth/email/verify/firebase', [
            'id_token' => 'invalid-token',
        ])->assertStatus(422);

        $this->assertNull($user->fresh()->email_verified_at);
    }

    public function test_valid_signed_link_verifies_the_correct_user(): void
    {
        $user = User::factory()->unverified()->create();

        $this->getJson($this->verifyUrl($user))
            ->assertOk()
            ->assertJsonPath('data.email_verified', true);

        $this->assertNotNull($user->fresh()->email_verified_at);
    }

    public function test_invalid_hash_and_tampered_signature_are_rejected(): void
    {
        $user = User::factory()->unverified()->create();

        $this->getJson($this->verifyUrl($user, 'invalid-hash'))
            ->assertStatus(403)
            ->assertJsonPath('success', false);

        $this->getJson($this->verifyUrl($user).'&extra=1')
            ->assertStatus(403);
        $this->assertNull($user->fresh()->email_verified_at);
    }

    public function test_unverified_user_cannot_login_but_verified_user_can(): void
    {
        $user = User::factory()->unverified()->create([
            'email' => 'login-verification@example.com',
            'password' => bcrypt('Password123!'),
            'status' => 'active',
        ]);

        $this->postJson('/api/v1/auth/login', [
            'email' => $user->email,
            'password' => 'Password123!',
        ])->assertStatus(422)->assertJsonMissingPath('data.token');

        $user->markEmailAsVerified();

        $this->postJson('/api/v1/auth/login', [
            'email' => $user->email,
            'password' => 'Password123!',
        ])->assertOk()->assertJsonPath('data.token', fn ($token) => ! empty($token));
    }
}
