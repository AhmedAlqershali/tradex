<?php

namespace Tests\Feature\Auth;

use App\Contracts\Services\GoogleTokenVerifierInterface;
use App\Exceptions\GoogleAuthenticationException;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\PersonalAccessToken;
use Tests\TestCase;

class GoogleAuthenticationTest extends TestCase
{
    use RefreshDatabase;

    private function mockGoogle(array $identity): void
    {
        $this->mock(GoogleTokenVerifierInterface::class, function ($mock) use ($identity) {
            $mock->shouldReceive('verify')
                ->once()
                ->with('google-credential')
                ->andReturn($identity);
        });
    }

    private function googleIdentity(
        string $sub = 'google-sub-123',
        string $email = 'google@example.com',
        string $name = 'Google User',
    ): array {
        return compact('sub', 'email', 'name');
    }

    public function test_invalid_google_credential_is_rejected(): void
    {
        $this->mock(GoogleTokenVerifierInterface::class, function ($mock) {
            $mock->shouldReceive('verify')
                ->once()
                ->with('google-credential')
                ->andThrow(new GoogleAuthenticationException('Invalid or expired Google credential.'));
        });

        $this->postJson('/api/v1/auth/google', [
            'credential' => 'google-credential',
        ])->assertUnauthorized()
            ->assertJsonPath('success', false)
            ->assertJsonPath('data', null);

        $this->assertDatabaseCount('users', 0);
    }

    public function test_google_auth_creates_a_client_and_issues_a_sanctum_token(): void
    {
        $this->mockGoogle($this->googleIdentity());

        $response = $this->postJson('/api/v1/auth/google', [
            'credential'  => 'google-credential',
            'device_name' => 'test-device',
        ])->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'data' => [
                    'user' => ['id', 'name', 'email', 'role'],
                    'token',
                ],
            ]);

        $user = User::where('email', 'google@example.com')->firstOrFail();

        $this->assertSame('client', $user->role);
        $this->assertSame('active', $user->status);
        $this->assertSame('google-sub-123', $user->google_id);
        $this->assertNotNull($user->email_verified_at);
        $this->assertSame(1, $user->tokens()->where('name', 'test-device')->count());
        $this->assertStringContainsString('|', $response->json('data.token'));
        $this->assertArrayNotHasKey('google_id', $response->json('data.user'));
    }

    public function test_google_auth_does_not_create_a_duplicate_for_an_existing_email(): void
    {
        $user = User::factory()->client()->create([
            'email' => 'Existing@Example.com',
            'google_id' => null,
        ]);
        $this->mockGoogle($this->googleIdentity(
            email: 'existing@example.com',
            name: 'Updated Google Name',
        ));

        $this->postJson('/api/v1/auth/google', [
            'credential' => 'google-credential',
        ])->assertOk()
            ->assertJsonPath('data.user.id', $user->id);

        $this->assertDatabaseCount('users', 1);
        $this->assertSame(
            'google-sub-123',
            $user->fresh()->google_id
        );
        $this->assertSame('Existing@Example.com', $user->fresh()->email);
    }

    public function test_already_linked_google_account_can_authenticate_again(): void
    {
        $user = User::factory()->merchant()->create([
            'email' => 'merchant@example.com',
            'google_id' => 'google-sub-123',
        ]);
        $this->mockGoogle($this->googleIdentity(email: 'merchant@example.com'));

        $this->postJson('/api/v1/auth/google', [
            'credential' => 'google-credential',
        ])->assertOk()
            ->assertJsonPath('data.user.id', $user->id)
            ->assertJsonPath('data.user.role', 'merchant');

        $this->assertDatabaseCount('users', 1);
        $this->assertSame(1, PersonalAccessToken::where('tokenable_id', $user->id)->count());
    }

    public function test_google_subject_conflict_is_rejected(): void
    {
        User::factory()->client()->create([
            'email' => 'first@example.com',
            'google_id' => 'google-sub-123',
        ]);
        $this->mockGoogle($this->googleIdentity(email: 'second@example.com'));

        $this->postJson('/api/v1/auth/google', [
            'credential' => 'google-credential',
        ])->assertStatus(409)
            ->assertJsonPath('success', false);

        $this->assertDatabaseMissing('users', ['email' => 'second@example.com']);
    }

    public function test_existing_google_link_conflict_is_rejected(): void
    {
        $user = User::factory()->client()->create([
            'email' => 'linked@example.com',
            'google_id' => 'different-google-sub',
        ]);
        $this->mockGoogle($this->googleIdentity(email: 'linked@example.com'));

        $this->postJson('/api/v1/auth/google', [
            'credential' => 'google-credential',
        ])->assertStatus(409)
            ->assertJsonPath('success', false);

        $this->assertSame('different-google-sub', $user->fresh()->google_id);
    }

    public function test_google_auth_rejects_an_inactive_user_before_issuing_a_token(): void
    {
        $user = User::factory()->client()->create([
            'email' => 'inactive@example.com',
            'google_id' => 'google-sub-123',
            'status' => 'inactive',
        ]);
        $this->mockGoogle($this->googleIdentity(email: 'inactive@example.com'));

        $this->postJson('/api/v1/auth/google', [
            'credential' => 'google-credential',
        ])->assertStatus(422)
            ->assertJsonPath('success', false);

        $this->assertSame(0, $user->tokens()->count());
    }

    public function test_google_auth_rejects_a_banned_user_before_issuing_a_token(): void
    {
        $user = User::factory()->client()->create([
            'email' => 'banned@example.com',
            'google_id' => 'google-sub-123',
            'status' => 'banned',
        ]);
        $this->mockGoogle($this->googleIdentity(email: 'banned@example.com'));

        $this->postJson('/api/v1/auth/google', [
            'credential' => 'google-credential',
        ])->assertStatus(422)
            ->assertJsonPath('success', false);

        $this->assertSame(0, $user->tokens()->count());
    }

    public function test_google_auth_never_authenticates_an_admin_account(): void
    {
        $user = User::factory()->admin()->create([
            'email' => 'admin@example.com',
            'google_id' => null,
        ]);
        $this->mockGoogle($this->googleIdentity(email: 'admin@example.com'));

        $this->postJson('/api/v1/auth/google', [
            'credential' => 'google-credential',
        ])->assertForbidden()
            ->assertJsonPath('success', false);

        $this->assertNull($user->fresh()->google_id);
        $this->assertSame(0, $user->tokens()->count());
    }
}