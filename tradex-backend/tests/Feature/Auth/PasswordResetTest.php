<?php

namespace Tests\Feature\Auth;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Facades\Password;
use Tests\TestCase;

/**
 * Password reset flow tests.
 *
 * Uses Password::broker()->createToken() to generate real tokens
 * without sending emails. No real mail is dispatched.
 */
class PasswordResetTest extends TestCase
{
    use RefreshDatabase;

    // =========================================================================
    // POST /api/v1/auth/password/forgot
    // =========================================================================

    public function test_forgot_password_returns_200_for_registered_email(): void
    {
        Notification::fake();

        User::factory()->create(['email' => 'user@example.com']);

        $this->postJson('/api/v1/auth/password/forgot', [
            'email' => 'user@example.com',
        ])
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['success', 'message', 'data']);
    }

    public function test_forgot_password_returns_200_for_unknown_email(): void
    {
        // Must not reveal whether the email exists (anti-enumeration).
        $this->postJson('/api/v1/auth/password/forgot', [
            'email' => 'nobody@example.com',
        ])
            ->assertOk()
            ->assertJsonPath('success', true);
    }

    public function test_forgot_password_requires_email_field(): void
    {
        $this->postJson('/api/v1/auth/password/forgot', [])
            ->assertStatus(422)
            ->assertJsonPath('success', false)
            ->assertJsonStructure(['errors' => ['email']]);
    }

    public function test_forgot_password_rejects_invalid_email_format(): void
    {
        $this->postJson('/api/v1/auth/password/forgot', ['email' => 'not-an-email'])
            ->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    // =========================================================================
    // POST /api/v1/auth/password/reset
    // =========================================================================

    public function test_password_can_be_reset_with_valid_token(): void
    {
        $user  = User::factory()->create(['email' => 'user@example.com']);
        $token = Password::broker()->createToken($user);

        $this->postJson('/api/v1/auth/password/reset', [
            'email'                 => 'user@example.com',
            'token'                 => $token,
            'password'              => 'NewPassword123!',
            'password_confirmation' => 'NewPassword123!',
        ])
            ->assertOk()
            ->assertJsonPath('success', true);

        // Verify the new password works
        $this->assertTrue(Hash::check('NewPassword123!', $user->fresh()->password));
    }

    public function test_reset_fails_with_invalid_token(): void
    {
        User::factory()->create(['email' => 'user@example.com']);

        $this->postJson('/api/v1/auth/password/reset', [
            'email'                 => 'user@example.com',
            'token'                 => 'completely-invalid-token',
            'password'              => 'NewPassword123!',
            'password_confirmation' => 'NewPassword123!',
        ])
            ->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_reset_does_not_reveal_unknown_email(): void
    {
        $response = $this->postJson('/api/v1/auth/password/reset', [
            'email'                 => 'nobody@example.com',
            'token'                 => 'completely-invalid-token',
            'password'              => 'NewPassword123!',
            'password_confirmation' => 'NewPassword123!',
        ]);

        $response->assertStatus(422)
            ->assertJsonPath('message', 'Validation failed.')
            ->assertDontSee('No account found with that email address.')
            ->assertDontSee('nobody@example.com');
    }

    public function test_reset_requires_email_token_and_password(): void
    {
        $this->postJson('/api/v1/auth/password/reset', [])
            ->assertStatus(422)
            ->assertJsonPath('success', false)
            ->assertJsonStructure(['errors']);
    }

    public function test_reset_requires_password_confirmation(): void
    {
        $user  = User::factory()->create(['email' => 'user@example.com']);
        $token = Password::broker()->createToken($user);

        $this->postJson('/api/v1/auth/password/reset', [
            'email'    => 'user@example.com',
            'token'    => $token,
            'password' => 'NewPassword123!',
            // no password_confirmation
        ])
            ->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_reset_requires_password_min_length(): void
    {
        $user  = User::factory()->create(['email' => 'user@example.com']);
        $token = Password::broker()->createToken($user);

        $this->postJson('/api/v1/auth/password/reset', [
            'email'                 => 'user@example.com',
            'token'                 => $token,
            'password'              => 'short',
            'password_confirmation' => 'short',
        ])
            ->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_reset_response_has_standard_envelope(): void
    {
        Notification::fake();

        $user  = User::factory()->create(['email' => 'user@example.com']);
        $token = Password::broker()->createToken($user);

        $this->postJson('/api/v1/auth/password/reset', [
            'email'                 => 'user@example.com',
            'token'                 => $token,
            'password'              => 'NewPassword123!',
            'password_confirmation' => 'NewPassword123!',
        ])
            ->assertOk()
            ->assertJsonStructure(['success', 'message', 'data']);
    }
}
