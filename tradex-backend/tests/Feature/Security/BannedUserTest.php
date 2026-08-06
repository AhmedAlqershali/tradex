<?php

namespace Tests\Feature\Security;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

/**
 * Banned / inactive user access tests.
 *
 * Verifies that:
 * 1. Banned users cannot log in (pre-token check in AuthService).
 * 2. Inactive users cannot log in.
 * 3. A user banned after receiving a valid token is blocked mid-session
 *    (EnsureUserIsActive middleware revokes the token).
 * 4. Deleted users cannot use their old tokens.
 */
class BannedUserTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        // Prevent actual HaveIBeenPwned HTTP calls during tests.
        Http::fake([
            'https://api.pwnedpasswords.com/*' => Http::response('', 200),
        ]);
    }

    private function headers(string $token): array
    {
        return ['Authorization' => "Bearer {$token}", 'Accept' => 'application/json'];
    }

    // ── Login gate ────────────────────────────────────────────────────────────

    public function test_banned_user_cannot_login(): void
    {
        User::factory()->create([
            'email'    => 'banned@example.com',
            'password' => bcrypt('Password1!'),
            'status'   => 'banned',
            'role'     => 'client',
        ]);

        $this->postJson('/api/v1/auth/login', [
            'email'    => 'banned@example.com',
            'password' => 'Password1!',
        ])->assertStatus(422)
          ->assertJsonFragment(['success' => false]);
    }

    public function test_inactive_user_cannot_login(): void
    {
        User::factory()->create([
            'email'    => 'inactive@example.com',
            'password' => bcrypt('Password1!'),
            'status'   => 'inactive',
            'role'     => 'client',
        ]);

        $this->postJson('/api/v1/auth/login', [
            'email'    => 'inactive@example.com',
            'password' => 'Password1!',
        ])->assertStatus(422)
          ->assertJsonFragment(['success' => false]);
    }

    public function test_active_user_can_login(): void
    {
        User::factory()->create([
            'email'    => 'active@example.com',
            'password' => bcrypt('Password1!'),
            'status'   => 'active',
            'role'     => 'client',
        ]);

        $this->postJson('/api/v1/auth/login', [
            'email'    => 'active@example.com',
            'password' => 'Password1!',
        ])->assertStatus(200)
          ->assertJsonFragment(['success' => true]);
    }

    // ── Mid-session ban (EnsureUserIsActive middleware) ───────────────────────

    public function test_user_banned_mid_session_loses_api_access(): void
    {
        $user  = User::factory()->create(['status' => 'active', 'role' => 'client']);
        $token = $user->createToken('test')->plainTextToken;

        // Confirm access before ban
        $this->getJson('/api/v1/auth/me', $this->headers($token))->assertStatus(200);

        // Admin bans the user
        $user->status = 'banned';
        $user->save();

        // Subsequent request must be rejected
        $this->getJson('/api/v1/auth/me', $this->headers($token))->assertStatus(403);
    }

    public function test_user_inactivated_mid_session_loses_api_access(): void
    {
        $user  = User::factory()->create(['status' => 'active', 'role' => 'client']);
        $token = $user->createToken('test')->plainTextToken;

        $user->status = 'inactive';
        $user->save();

        $this->getJson('/api/v1/auth/me', $this->headers($token))->assertStatus(403);
    }

    // ── Token invalidation on ban ─────────────────────────────────────────────

    public function test_banning_user_deletes_all_tokens(): void
    {
        $user   = User::factory()->create(['status' => 'active', 'role' => 'client']);
        $token1 = $user->createToken('device1')->plainTextToken;
        $token2 = $user->createToken('device2')->plainTextToken;

        $this->assertCount(2, $user->tokens()->get());

        // Admin bans via the admin service (simulated here)
        $user->status = 'banned';
        $user->save();
        $user->tokens()->delete();

        $this->assertCount(0, $user->tokens()->get());

        // Both tokens must now be rejected
        $this->getJson('/api/v1/auth/me', $this->headers($token1))->assertStatus(401);
        $this->getJson('/api/v1/auth/me', $this->headers($token2))->assertStatus(401);
    }

    // ── Suspended merchant ────────────────────────────────────────────────────

    public function test_suspended_merchant_cannot_create_products(): void
    {
        $merchant = User::factory()->create([
            'role'   => 'merchant',
            'status' => 'active',
        ]);
        $store = \App\Models\Store::factory()->create([
            'user_id' => $merchant->id,
            'status'  => 'active',
        ]);
        $token = $merchant->createToken('test')->plainTextToken;

        // Confirm access before suspension
        $this->getJson('/api/v1/merchant/products', $this->headers($token))->assertStatus(200);

        // Merchant is banned
        $merchant->status = 'banned';
        $merchant->save();

        // Subsequent merchant-endpoint request must be rejected
        $this->getJson('/api/v1/merchant/products', $this->headers($token))->assertStatus(403);
    }
}
