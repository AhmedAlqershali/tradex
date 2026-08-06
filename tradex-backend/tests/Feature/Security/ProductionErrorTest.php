<?php

namespace Tests\Feature\Security;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Production error response tests.
 *
 * Verifies that all error status codes produce the standard API envelope
 * { success, message, data, errors? } regardless of APP_DEBUG setting,
 * and never expose stack traces or internal details to API consumers.
 */
class ProductionErrorTest extends TestCase
{
    use RefreshDatabase;

    // =========================================================================
    // 401 — Unauthenticated
    // =========================================================================

    public function test_401_returns_standard_envelope(): void
    {
        $this->getJson('/api/v1/auth/me')
            ->assertStatus(401)
            ->assertJsonPath('success', false)
            ->assertJsonPath('data', null)
            ->assertJsonStructure(['success', 'message', 'data']);
    }

    // =========================================================================
    // 403 — Forbidden (role enforcement)
    // =========================================================================

    public function test_403_returns_standard_envelope_for_wrong_role(): void
    {
        $client = User::factory()->client()->create();
        $token  = $client->createToken('test')->plainTextToken;

        $this->getJson('/api/v1/admin/dashboard', [
            'Authorization' => "Bearer {$token}",
            'Accept'        => 'application/json',
        ])
            ->assertStatus(403)
            ->assertJsonPath('success', false)
            ->assertJsonPath('data', null)
            ->assertJsonStructure(['success', 'message', 'data']);
    }

    public function test_403_returns_standard_envelope_for_banned_user(): void
    {
        $user  = User::factory()->client()->create(['status' => 'banned']);
        $token = $user->createToken('test')->plainTextToken;

        $this->getJson('/api/v1/profile', [
            'Authorization' => "Bearer {$token}",
            'Accept'        => 'application/json',
        ])
            ->assertStatus(403)
            ->assertJsonPath('success', false)
            ->assertJsonPath('data', null);
    }

    // =========================================================================
    // 404 — Not Found
    // =========================================================================

    public function test_404_returns_standard_envelope(): void
    {
        $this->getJson('/api/v1/this-route-does-not-exist')
            ->assertStatus(404)
            ->assertJsonPath('success', false)
            ->assertJsonPath('data', null)
            ->assertJsonStructure(['success', 'message', 'data']);
    }

    public function test_404_does_not_expose_laravel_debug_info(): void
    {
        $response = $this->getJson('/api/v1/nonexistent-route-xyz');

        $body = $response->json();

        // The response must not contain Laravel debug keys
        $this->assertArrayNotHasKey('exception', $body);
        $this->assertArrayNotHasKey('trace', $body);
        $this->assertArrayNotHasKey('file', $body);
        $this->assertArrayNotHasKey('line', $body);
    }

    // =========================================================================
    // 422 — Validation Error
    // =========================================================================

    public function test_422_returns_standard_envelope_with_errors(): void
    {
        $this->postJson('/api/v1/auth/login', [])
            ->assertStatus(422)
            ->assertJsonPath('success', false)
            ->assertJsonStructure(['success', 'message', 'data', 'errors']);
    }

    public function test_422_errors_field_contains_field_level_messages(): void
    {
        $this->postJson('/api/v1/auth/register/client', [])
            ->assertStatus(422)
            ->assertJsonPath('success', false)
            ->assertJsonStructure(['errors' => ['email', 'password']]);
    }

    // =========================================================================
    // 405 — Method Not Allowed (handled by 404 in current config)
    // =========================================================================

    public function test_delete_on_get_only_route_returns_error_response(): void
    {
        // Even method-not-allowed responses must be JSON-formatted
        $this->deleteJson('/api/v1/health')
            ->assertJsonPath('success', false);
    }

    // =========================================================================
    // Response envelope consistency across all error codes
    // =========================================================================

    public function test_all_error_responses_include_data_null(): void
    {
        $errors = [
            ['method' => 'getJson',  'url' => '/api/v1/auth/me'],                    // 401
            ['method' => 'getJson',  'url' => '/api/v1/this-does-not-exist-123'],    // 404
            ['method' => 'postJson', 'url' => '/api/v1/auth/login', 'body' => []],  // 422
        ];

        foreach ($errors as $case) {
            $method   = $case['method'];
            $response = isset($case['body'])
                ? $this->$method($case['url'], $case['body'])
                : $this->$method($case['url']);

            $this->assertNull(
                $response->json('data'),
                "Expected data=null for {$case['url']}, got: " . json_encode($response->json('data'))
            );
        }
    }
}
