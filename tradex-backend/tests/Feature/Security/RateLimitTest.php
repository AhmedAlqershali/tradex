<?php

namespace Tests\Feature\Security;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\RateLimiter;
use Tests\TestCase;

/**
 * Rate limiting tests.
 *
 * Verifies that throttle middleware returns 429 responses with the
 * correct standard API envelope: { success: false, data: null, message, errors }.
 */
class RateLimitTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        // Clear all rate limiter state before each test so counts don't bleed.
        RateLimiter::clear('auth|127.0.0.1');
    }

    // =========================================================================
    // throttle:auth  — 5 req/min/IP on login, register, and password reset
    // =========================================================================

    public function test_login_endpoint_is_rate_limited_after_5_requests(): void
    {
        // Exhaust the 5-request-per-minute auth limit
        for ($i = 0; $i < 5; $i++) {
            $this->postJson('/api/v1/auth/login', [
                'email'    => "attempt{$i}@example.com",
                'password' => 'wrong',
            ]);
        }

        // The 6th request must be throttled
        $this->postJson('/api/v1/auth/login', [
            'email'    => 'extra@example.com',
            'password' => 'wrong',
        ])
            ->assertStatus(429)
            ->assertJsonPath('success', false)
            ->assertJsonPath('data', null);
    }

    public function test_429_response_has_standard_envelope(): void
    {
        // Exhaust the auth rate limit
        for ($i = 0; $i < 5; $i++) {
            $this->postJson('/api/v1/auth/login', [
                'email'    => "x{$i}@e.com",
                'password' => 'x',
            ]);
        }

        $this->postJson('/api/v1/auth/login', ['email' => 'y@e.com', 'password' => 'y'])
            ->assertStatus(429)
            ->assertJsonStructure(['success', 'message', 'data']);
    }

    public function test_forgot_password_is_rate_limited(): void
    {
        for ($i = 0; $i < 5; $i++) {
            $this->postJson('/api/v1/auth/password/forgot', ['email' => "u{$i}@example.com"]);
        }

        $this->postJson('/api/v1/auth/password/forgot', ['email' => 'u6@example.com'])
            ->assertStatus(429)
            ->assertJsonPath('success', false)
            ->assertJsonPath('data', null);
    }

    public function test_register_endpoint_is_rate_limited(): void
    {
        for ($i = 0; $i < 5; $i++) {
            $this->postJson('/api/v1/auth/register/client', [
                'name'                  => "User {$i}",
                'email'                 => "user{$i}@example.com",
                'password'              => 'Password123!',
                'password_confirmation' => 'Password123!',
            ]);
        }

        $this->postJson('/api/v1/auth/register/client', [
            'name'                  => 'Extra User',
            'email'                 => 'extra@example.com',
            'password'              => 'Password123!',
            'password_confirmation' => 'Password123!',
        ])
            ->assertStatus(429)
            ->assertJsonPath('success', false);
    }
}
