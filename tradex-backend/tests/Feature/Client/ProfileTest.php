<?php

namespace Tests\Feature\Client;

use App\Models\Store;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

/**
 * Tests for GET /profile, PUT /profile, PUT /profile/password, POST /profile/avatar.
 * All roles (client, merchant, admin) share the same profile endpoints.
 */
class ProfileTest extends TestCase
{
    use RefreshDatabase;

    private function actingAsRole(string $role = 'client'): array
    {
        $user  = User::factory()->{$role}()->create(['status' => 'active']);
        $token = $user->createToken('test')->plainTextToken;

        return compact('user', 'token');
    }

    private function headers(string $token): array
    {
        return ['Authorization' => "Bearer {$token}", 'Accept' => 'application/json'];
    }

    // ── GET /profile ───────────────────────────────────────────────────────────

    public function test_unauthenticated_cannot_view_profile(): void
    {
        $this->getJson('/api/v1/profile')->assertUnauthorized();
    }

    public function test_client_can_view_own_profile(): void
    {
        ['user' => $user, 'token' => $token] = $this->actingAsRole('client');

        $this->getJson('/api/v1/profile', $this->headers($token))
            ->assertOk()
            ->assertJson(['success' => true])
            ->assertJsonPath('data.email', $user->email)
            ->assertJsonPath('data.role', 'client');
    }

    public function test_merchant_profile_includes_stores(): void
    {
        ['user' => $user, 'token' => $token] = $this->actingAsRole('merchant');
        Store::factory()->forUser($user)->create(['store_name' => 'My Shop']);

        $response = $this->getJson('/api/v1/profile', $this->headers($token))
            ->assertOk()
            ->assertJson(['success' => true]);

        $this->assertNotEmpty($response->json('data.stores'));
    }

    // ── PUT /profile ───────────────────────────────────────────────────────────

    public function test_client_can_update_name_and_phone(): void
    {
        ['user' => $user, 'token' => $token] = $this->actingAsRole('client');

        $this->putJson('/api/v1/profile', [
            'name'  => 'Updated Name',
            'phone' => '0501112222',
        ], $this->headers($token))
            ->assertOk()
            ->assertJsonPath('data.name', 'Updated Name')
            ->assertJsonPath('data.phone', '0501112222');

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'name' => 'Updated Name',
            'phone' => '0501112222',
        ]);
    }

    public function test_client_can_clear_nullable_phone(): void
    {
        ['user' => $user, 'token' => $token] = $this->actingAsRole('client');
        $user->update(['phone' => '0501112222']);

        $this->putJson('/api/v1/profile', [
            'phone' => null,
        ], $this->headers($token))
            ->assertOk()
            ->assertJsonPath('data.phone', null);

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'phone' => null,
        ]);
    }

    public function test_profile_retrieval_returns_persisted_values_after_update(): void
    {
        ['user' => $user, 'token' => $token] = $this->actingAsRole('client');

        $this->putJson('/api/v1/profile', [
            'name' => 'Authoritative Name',
            'email' => 'authoritative@example.com',
            'phone' => '0509998888',
        ], $this->headers($token))->assertOk();

        $this->getJson('/api/v1/profile', $this->headers($token))
            ->assertOk()
            ->assertJsonPath('data.id', $user->id)
            ->assertJsonPath('data.name', 'Authoritative Name')
            ->assertJsonPath('data.email', 'authoritative@example.com')
            ->assertJsonPath('data.phone', '0509998888');
    }

    public function test_client_can_persist_and_restore_location(): void
    {
        ['user' => $user, 'token' => $token] = $this->actingAsRole('client');

        $this->putJson('/api/v1/profile', [
            'region' => 'الوسطى',
            'location_name' => 'دير البلح',
            'latitude' => 31.4175,
            'longitude' => 34.3732,
        ], $this->headers($token))
            ->assertOk()
            ->assertJsonPath('data.region', 'الوسطى')
            ->assertJsonPath('data.location_name', 'دير البلح')
            ->assertJsonPath('data.latitude', 31.4175)
            ->assertJsonPath('data.longitude', 34.3732);

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'region' => 'الوسطى',
            'location_name' => 'دير البلح',
        ]);

        $this->getJson('/api/v1/profile', $this->headers($token))
            ->assertOk()
            ->assertJsonPath('data.region', 'الوسطى')
            ->assertJsonPath('data.location_name', 'دير البلح');
    }

    public function test_location_coordinates_are_validated(): void
    {
        ['token' => $token] = $this->actingAsRole('client');

        $this->putJson('/api/v1/profile', [
            'latitude' => 91,
            'longitude' => -181,
        ], $this->headers($token))
            ->assertStatus(422)
            ->assertJson(['success' => false]);
    }

    public function test_client_can_update_email_to_unique_address(): void
    {
        ['user' => $user, 'token' => $token] = $this->actingAsRole('client');

        $this->putJson('/api/v1/profile', [
            'name'  => $user->name,
            'email' => 'newemail@example.com',
        ], $this->headers($token))
            ->assertOk()
            ->assertJsonPath('data.email', 'newemail@example.com');
    }

    public function test_profile_update_rejects_email_already_taken(): void
    {
        User::factory()->create(['email' => 'taken@example.com']);
        ['token' => $token] = $this->actingAsRole('client');

        $this->putJson('/api/v1/profile', [
            'email' => 'taken@example.com',
        ], $this->headers($token))
            ->assertStatus(422)
            ->assertJson(['success' => false]);
    }

    public function test_profile_update_allows_keeping_own_email(): void
    {
        ['user' => $user, 'token' => $token] = $this->actingAsRole('client');

        $this->putJson('/api/v1/profile', [
            'name'  => 'Same Email',
            'email' => $user->email,
        ], $this->headers($token))
            ->assertOk()
            ->assertJsonPath('data.email', $user->email);
    }

    // ── PUT /profile/password ──────────────────────────────────────────────────

    public function test_client_can_change_password(): void
    {
        ['user' => $user, 'token' => $token] = $this->actingAsRole('client');
        // Recreate with known password
        $user->update(['password' => bcrypt('OldPassword1!')]);

        $this->putJson('/api/v1/profile/password', [
            'current_password'      => 'OldPassword1!',
            'new_password'          => 'NewPassword1!',
            'new_password_confirmation' => 'NewPassword1!',
        ], $this->headers($token))
            ->assertOk()
            ->assertJson(['success' => true]);
    }

    public function test_wrong_current_password_returns_422(): void
    {
        ['token' => $token] = $this->actingAsRole('client');

        $this->putJson('/api/v1/profile/password', [
            'current_password'          => 'WrongPassword!',
            'new_password'              => 'NewPassword1!',
            'new_password_confirmation' => 'NewPassword1!',
        ], $this->headers($token))
            ->assertStatus(422)
            ->assertJson(['success' => false]);
    }

    public function test_password_confirmation_must_match(): void
    {
        ['user' => $user, 'token' => $token] = $this->actingAsRole('client');
        $user->update(['password' => bcrypt('OldPassword1!')]);

        $this->putJson('/api/v1/profile/password', [
            'current_password'          => 'OldPassword1!',
            'new_password'              => 'NewPassword1!',
            'new_password_confirmation' => 'DifferentPassword!',
        ], $this->headers($token))
            ->assertStatus(422);
    }

    // ── POST /profile/avatar ───────────────────────────────────────────────────

    public function test_client_can_upload_avatar(): void
    {
        Storage::fake('public');
        ['token' => $token] = $this->actingAsRole('client');

        $this->postJson('/api/v1/profile/avatar', [
            'avatar' => UploadedFile::fake()->image('avatar.jpg', 200, 200),
        ], $this->headers($token))
            ->assertOk()
            ->assertJson(['success' => true]);

        Storage::disk('public')->assertExists(
            collect(Storage::disk('public')->allFiles('avatars'))->first()
        );
    }

    public function test_avatar_upload_requires_image(): void
    {
        Storage::fake('public');
        ['token' => $token] = $this->actingAsRole('client');

        $this->postJson('/api/v1/profile/avatar', [
            'avatar' => UploadedFile::fake()->create('document.pdf', 100, 'application/pdf'),
        ], $this->headers($token))
            ->assertStatus(422);
    }

    public function test_avatar_upload_requires_field(): void
    {
        ['token' => $token] = $this->actingAsRole('client');

        $this->postJson('/api/v1/profile/avatar', [], $this->headers($token))
            ->assertStatus(422);
    }
}
