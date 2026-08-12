<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Subscription;
use Illuminate\Auth\Notifications\VerifyEmail;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Facades\Storage;
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
        Notification::assertNotSentTo(
            User::where('email', 'client@example.com')->first(),
            VerifyEmail::class
        );

        $this->postJson('/api/v1/auth/login', [
            'email'    => 'client@example.com',
            'password' => 'Password123!',
        ])->assertOk();
    }

    public function test_registration_response_has_a_null_server_avatar_until_upload(): void
    {
        $response = $this->postJson('/api/v1/auth/register/client', [
            'name'                  => 'Avatar Client',
            'email'                 => 'avatar-registration@example.com',
            'phone'                 => '0501234567',
            'password'              => 'Password123!',
            'password_confirmation' => 'Password123!',
        ])->assertStatus(201);

        $response->assertJsonPath('data.user.avatar', null);
    }

    public function test_registration_ignores_privileged_user_fields(): void
    {
        $response = $this->postJson('/api/v1/auth/register/client', [
            'name'                  => 'Untrusted Client',
            'email'                 => 'untrusted@example.com',
            'phone'                 => '0501234567',
            'password'              => 'Password123!',
            'password_confirmation' => 'Password123!',
            'role'                  => 'admin',
            'is_admin'              => true,
            'status'                => 'active',
            'permissions'           => ['*'],
        ]);

        $response->assertCreated()
            ->assertJsonPath('data.user.role', 'client')
            ->assertJsonMissingPath('data.user.password');

        $this->assertDatabaseHas('users', [
            'email'  => 'untrusted@example.com',
            'role'   => 'client',
            'status' => 'active',
        ]);
    }

    public function test_merchant_can_register(): void
    {
        Notification::fake();

        $response = $this->postJson('/api/v1/auth/register/merchant', [
            'name'                  => 'Test Merchant',
            'email'                 => 'merchant@example.com',
            'phone'                 => '0509876543',
            'password'              => 'Password123!',
            'password_confirmation' => 'Password123!',
            'store_name'            => 'Test Store',
        ])
            ->assertStatus(201)
            ->assertJson(['success' => true])
            ->assertJsonPath('data.user.current_subscription.type', 'trial')
            ->assertJsonPath('data.user.current_subscription.status', 'active')
            ->assertJsonPath('data.user.current_subscription.is_trial', true)
            ->assertJsonPath('data.user.current_subscription.is_entitled', true);

        $merchant = User::where('email', 'merchant@example.com')->firstOrFail();
        $trial = Subscription::where('user_id', $merchant->id)->firstOrFail();

        $this->assertSame('merchant', $merchant->role);
        $this->assertSame('trial', $trial->type);
        $this->assertSame('active', $trial->status);
        $this->assertTrue($trial->ends_at->equalTo($trial->starts_at->copy()->addDays(14)));
        $this->assertSame(1, Subscription::where('user_id', $merchant->id)->count());
        $this->assertDatabaseHas('stores', ['store_name' => 'Test Store']);
        Notification::assertNotSentTo(
            $merchant,
            VerifyEmail::class
        );

        $this->getJson('/api/v1/auth/me', $this->headers($response->json('data.token')))
            ->assertOk()
            ->assertJsonPath('data.current_subscription.type', 'trial')
            ->assertJsonPath('data.current_subscription.is_entitled', true);
    }

    public function test_client_and_admin_profiles_do_not_receive_merchant_trial_state(): void
    {
        $client = User::factory()->client()->create();
        $admin = User::factory()->admin()->create();

        foreach ([$client, $admin] as $user) {
            $this->getJson('/api/v1/auth/me', $this->headers(
                $user->createToken('test')->plainTextToken,
            ))
                ->assertOk()
                ->assertJsonMissingPath('data.current_subscription');
        }

        $this->assertDatabaseCount('subscriptions', 0);
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

    public function test_login_returns_the_server_avatar_url_after_a_new_session(): void
    {
        Storage::fake('public');
        Storage::disk('public')->put('avatars/persisted-avatar.jpg', 'avatar bytes');

        User::factory()->create([
            'email'    => 'avatar@example.com',
            'password' => bcrypt('Password123!'),
            'role'     => 'client',
            'avatar'   => 'avatars/persisted-avatar.jpg',
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email'    => 'avatar@example.com',
            'password' => 'Password123!',
        ])->assertOk();

        $avatar = $response->json('data.user.avatar');
        $this->assertIsString($avatar);
        $this->assertNotFalse(filter_var($avatar, FILTER_VALIDATE_URL));
        $this->assertStringContainsString(
            '/storage/avatars/persisted-avatar.jpg',
            parse_url($avatar, PHP_URL_PATH),
        );
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

    public function test_logout_revokes_only_the_current_token(): void
    {
        $user = User::factory()->client()->create();
        $token = $user->createToken('device')->plainTextToken;
        $otherToken = $user->createToken('other-device')->plainTextToken;

        $this->postJson('/api/v1/auth/logout', [], $this->headers($token))
            ->assertOk();

        // Laravel's auth manager is shared across simulated requests in a
        // feature test. Clear its cached guard so this request resolves the
        // bearer token again, matching separate real HTTP requests.
        Auth::forgetGuards();
        $this->getJson('/api/v1/auth/me', $this->headers($token))
            ->assertUnauthorized();

        Auth::forgetGuards();
        $this->getJson('/api/v1/auth/me', $this->headers($otherToken))
            ->assertOk();
    }

    public function test_invalid_token_is_rejected(): void
    {
        $this->getJson('/api/v1/auth/me', $this->headers('not-a-valid-sanctum-token'))
            ->assertUnauthorized();
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
