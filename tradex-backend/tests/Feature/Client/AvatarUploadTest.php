<?php

namespace Tests\Feature\Client;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

/**
 * Tests for the profile avatar upload endpoint.
 *
 * POST /api/v1/profile/avatar — requires auth:sanctum.
 */
class AvatarUploadTest extends TestCase
{
    use RefreshDatabase;

    private function headers(string $token): array
    {
        return ['Authorization' => "Bearer {$token}", 'Accept' => 'application/json'];
    }

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('public');
    }

    // =========================================================================
    // Success cases
    // =========================================================================

    public function test_authenticated_user_can_upload_avatar(): void
    {
        $user  = User::factory()->create();
        $token = $user->createToken('test')->plainTextToken;

        $response = $this->postJson('/api/v1/profile/avatar', [
            'avatar' => UploadedFile::fake()->image('avatar.jpg', 200, 200),
        ], $this->headers($token));

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['data' => ['id', 'name', 'email', 'avatar']]);

        // Verify the file was actually stored
        $user->refresh();
        $this->assertNotNull($user->avatar);
        Storage::disk('public')->assertExists($user->avatar);
    }

    public function test_avatar_url_is_returned_in_response(): void
    {
        $user  = User::factory()->create();
        $token = $user->createToken('test')->plainTextToken;

        $response = $this->postJson('/api/v1/profile/avatar', [
            'avatar' => UploadedFile::fake()->image('photo.jpg'),
        ], $this->headers($token));

        $response->assertOk();
        $this->assertNotNull($response->json('data.avatar'));
    }

    public function test_avatar_is_returned_by_profile_after_upload(): void
    {
        $user  = User::factory()->create();
        $token = $user->createToken('test')->plainTextToken;

        $upload = $this->postJson('/api/v1/profile/avatar', [
            'avatar' => UploadedFile::fake()->image('session-avatar.jpg'),
        ], $this->headers($token))->assertOk();

        $avatar = $upload->json('data.avatar');
        $this->getJson('/api/v1/profile', $this->headers($token))
            ->assertOk()
            ->assertJsonPath('data.avatar', $avatar);
    }

    public function test_avatar_upload_only_updates_the_authenticated_user(): void
    {
        $owner = User::factory()->create();
        $other = User::factory()->create(['avatar' => 'avatars/other.jpg']);
        $token = $owner->createToken('test')->plainTextToken;

        $this->postJson('/api/v1/profile/avatar', [
            'avatar' => UploadedFile::fake()->image('owner.jpg'),
        ], $this->headers($token))->assertOk();

        $this->assertNotNull($owner->fresh()->avatar);
        $this->assertSame('avatars/other.jpg', $other->fresh()->avatar);
    }

    public function test_uploading_new_avatar_replaces_old_one(): void
    {
        Storage::disk('public')->put('avatars/old_avatar.jpg', 'dummy content');

        $user  = User::factory()->create(['avatar' => 'avatars/old_avatar.jpg']);
        $token = $user->createToken('test')->plainTextToken;

        $this->postJson('/api/v1/profile/avatar', [
            'avatar' => UploadedFile::fake()->image('new_avatar.jpg'),
        ], $this->headers($token))->assertOk();

        // Old avatar should be deleted
        Storage::disk('public')->assertMissing('avatars/old_avatar.jpg');

        // New avatar should exist
        $user->refresh();
        Storage::disk('public')->assertExists($user->avatar);
    }

    public function test_webp_avatar_is_accepted(): void
    {
        $user  = User::factory()->create();
        $token = $user->createToken('test')->plainTextToken;

        $this->postJson('/api/v1/profile/avatar', [
            'avatar' => UploadedFile::fake()->image('avatar.webp'),
        ], $this->headers($token))
            ->assertOk();
    }

    public function test_png_avatar_is_accepted(): void
    {
        $user  = User::factory()->create();
        $token = $user->createToken('test')->plainTextToken;

        $this->postJson('/api/v1/profile/avatar', [
            'avatar' => UploadedFile::fake()->image('avatar.png'),
        ], $this->headers($token))
            ->assertOk();
    }

    // =========================================================================
    // Validation failures
    // =========================================================================

    public function test_avatar_field_is_required(): void
    {
        $user  = User::factory()->create();
        $token = $user->createToken('test')->plainTextToken;

        $this->postJson('/api/v1/profile/avatar', [], $this->headers($token))
            ->assertStatus(422)
            ->assertJsonPath('success', false)
            ->assertJsonStructure(['errors' => ['avatar']]);
    }

    public function test_avatar_must_be_valid_image(): void
    {
        $user  = User::factory()->create();
        $token = $user->createToken('test')->plainTextToken;

        $this->postJson('/api/v1/profile/avatar', [
            'avatar' => UploadedFile::fake()->create('document.pdf', 100, 'application/pdf'),
        ], $this->headers($token))
            ->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_avatar_must_not_exceed_2mb(): void
    {
        $user  = User::factory()->create();
        $token = $user->createToken('test')->plainTextToken;

        $this->postJson('/api/v1/profile/avatar', [
            'avatar' => UploadedFile::fake()->image('large.jpg')->size(2049), // 2049 KB > 2 MB
        ], $this->headers($token))
            ->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    // =========================================================================
    // Authentication
    // =========================================================================

    public function test_unauthenticated_request_is_rejected(): void
    {
        $this->postJson('/api/v1/profile/avatar', [
            'avatar' => UploadedFile::fake()->image('avatar.jpg'),
        ])
            ->assertStatus(401)
            ->assertJsonPath('success', false);
    }

    public function test_response_has_standard_envelope(): void
    {
        $user  = User::factory()->create();
        $token = $user->createToken('test')->plainTextToken;

        $this->postJson('/api/v1/profile/avatar', [
            'avatar' => UploadedFile::fake()->image('avatar.jpg'),
        ], $this->headers($token))
            ->assertOk()
            ->assertJsonStructure(['success', 'message', 'data']);
    }
}
