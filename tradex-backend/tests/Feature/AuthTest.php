<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Auth\Notifications\VerifyEmail;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use RefreshDatabase;

    private function headers(string $token): array
    {
        return ['Authorization' => "Bearer {$token}", 'Accept' => 'application/json'];
    }

    // ── Registration ──────────────────────────────────────────────────────────

    public function test_client_can_register(): void
    {
        Notification::fake();

        $this->postJson('/api/v1/auth/register/client', [
            'name'                  => 'Test Client',
            'email'                 => 'client@example.com',
            'phone'                 => '0501234567',
            'password'              => 'Password123!',
            'password_confirmation' => 'Password123!',
        ])
            ->assertStatus(201)
            ->assertJson(['success' => true])
            ->assertJsonStructure(['data' => ['token', 'user']]);

        $this->assertDatabaseHas('users', ['email' => 'client@example.com', 'role' => 'client']);
        Notification::assertSentTo(
            User::where('email', 'client@example.com')->first(),
            VerifyEmail::class
        );
    }

    public function test_merchant_can_register(): void
    {
        Notification::fake();

        $this->postJson('/api/v1/auth/register/merchant', [
            'name'                  => 'Test Merchant',
            'email'                 => 'merchant@example.com',
            'phone'                 => '0509876543',
            'password'              => 'Password123!',
            'password_confirmation' => 'Password123!',
            'store_name'            => 'Test Store',
        ])
            ->assertStatus(201)
            ->assertJson(['success' => true]);

        $this->assertDatabaseHas('users', ['email' => 'merchant@example.com', 'role' => 'merchant']);
        $this->assertDatabaseHas('stores', ['store_name' => 'Test Store']);
        Notification::assertSentTo(
            User::where('email', 'merchant@example.com')->first(),
            VerifyEmail::class
        );
    }

    public function test_registration_requires_unique_email(): void
    {
        User::factory()->create(['email' => 'taken@example.com']);

        $this->postJson('/api/v1/auth/register/client', [
            'name'                  => 'Test',
            'email'                 => 'taken@example.com',
            'password'              => 'Password123!',
            'password_confirmation' => 'Password123!',
        ])
            ->assertStatus(422)
            ->assertJson(['success' => false]);
    }

    // ── Login ─────────────────────────────────────────────────────────────────

    public function test_user_can_login_with_correct_credentials(): void
    {
        User::factory()->create([
            'email'    => 'user@example.com',
            'password' => bcrypt('Password123!'),
            'role'     => 'client',
        ]);

        $this->postJson('/api/v1/auth/login', [
            'email'    => 'user@example.com',
            'password' => 'Password123!',
        ])
            ->assertOk()
            ->assertJson(['success' => true])
            ->assertJsonStructure(['data' => ['token', 'user']]);
    }

    public function test_login_fails_with_wrong_password(): void
    {
        User::factory()->create(['email' => 'user@example.com', 'password' => bcrypt('correct')]);

        $this->postJson('/api/v1/auth/login', [
            'email'    => 'user@example.com',
            'password' => 'wrong_password',
        ])
            ->assertStatus(422)
            ->assertJson(['success' => false]);
    }

    // ── Me / Logout ───────────────────────────────────────────────────────────

    public function test_authenticated_user_can_get_own_profile(): void
    {
        $user  = User::factory()->create(['role' => 'client']);
        $token = $user->createToken('test')->plainTextToken;

        $this->getJson('/api/v1/auth/me', $this->headers($token))
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.id', $user->id);
    }

    public function test_unauthenticated_request_returns_401(): void
    {
        $this->getJson('/api/v1/auth/me')
            ->assertStatus(401)
            ->assertJson(['success' => false]);
    }

    public function test_authenticated_user_can_logout(): void
    {
        $user  = User::factory()->create();
        $token = $user->createToken('test')->plainTextToken;

        $this->postJson('/api/v1/auth/logout', [], $this->headers($token))
            ->assertOk()
            ->assertJson(['success' => true]);
    }

    // ── Health check ──────────────────────────────────────────────────────────

    public function test_health_check_returns_ok(): void
    {
        $this->getJson('/api/v1/health')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.status', 'ok');
    }
}
