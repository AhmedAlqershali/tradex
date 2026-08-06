<?php

namespace Tests\Feature\Security;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Security headers tests.
 *
 * Verifies that every API response includes the expected security headers
 * added by the AddSecurityHeaders middleware.
 */
class SecurityHeadersTest extends TestCase
{
    use RefreshDatabase;

    public function test_api_responses_include_x_content_type_options(): void
    {
        $response = $this->getJson('/api/v1/health');

        $response->assertHeader('X-Content-Type-Options', 'nosniff');
    }

    public function test_api_responses_include_x_frame_options(): void
    {
        $response = $this->getJson('/api/v1/health');

        $response->assertHeader('X-Frame-Options', 'DENY');
    }

    public function test_api_responses_include_referrer_policy(): void
    {
        $response = $this->getJson('/api/v1/health');

        $response->assertHeader('Referrer-Policy', 'no-referrer');
    }

    public function test_api_responses_include_x_xss_protection(): void
    {
        $response = $this->getJson('/api/v1/health');

        $response->assertHeader('X-XSS-Protection', '0');
    }

    public function test_api_responses_include_permissions_policy(): void
    {
        $response = $this->getJson('/api/v1/health');

        $response->assertHeader('Permissions-Policy', 'camera=(), microphone=(), geolocation=()');
    }

    public function test_api_responses_include_content_security_policy(): void
    {
        $response = $this->getJson('/api/v1/health');

        $response->assertHeader('Content-Security-Policy', "default-src 'none'");
    }

    public function test_api_responses_include_cache_control_no_store(): void
    {
        $response = $this->getJson('/api/v1/health');

        $this->assertStringContainsString('no-store', $response->headers->get('Cache-Control'));
    }

    public function test_security_headers_present_on_401_responses(): void
    {
        $response = $this->getJson('/api/v1/auth/me');

        $response->assertStatus(401);
        $response->assertHeader('X-Content-Type-Options', 'nosniff');
        $response->assertHeader('X-Frame-Options', 'DENY');
    }

    public function test_security_headers_present_on_404_responses(): void
    {
        $response = $this->getJson('/api/v1/nonexistent-endpoint');

        $response->assertStatus(404);
        $response->assertHeader('X-Content-Type-Options', 'nosniff');
    }
}
