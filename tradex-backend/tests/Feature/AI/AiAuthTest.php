<?php

namespace Tests\Feature\AI;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Verify that every AI endpoint enforces authentication and role guards.
 * No AI provider mock needed — the 401/403 is returned before any service is called.
 */
class AiAuthTest extends TestCase
{
    use RefreshDatabase;

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    private function headers(string $token): array
    {
        return [
            'Authorization' => "Bearer {$token}",
            'Accept'        => 'application/json',
        ];
    }

    private function merchantToken(): string
    {
        $merchant = User::factory()->merchant()->create();
        $this->entitleMerchant($merchant);

        return $merchant->createToken('test')->plainTextToken;
    }

    private function clientToken(): string
    {
        return User::factory()->client()->create()
            ->createToken('test')->plainTextToken;
    }

    private function adminToken(): string
    {
        return User::factory()->admin()->create()
            ->createToken('test')->plainTextToken;
    }

    // =========================================================================
    // Unauthenticated — all endpoints must return 401
    // =========================================================================

    public function test_product_description_requires_auth(): void
    {
        $this->postJson('/api/v1/ai/product-description', ['context' => 'test'])
            ->assertStatus(401)
            ->assertJsonPath('success', false);
    }

    public function test_marketing_content_requires_auth(): void
    {
        $this->postJson('/api/v1/ai/marketing-content', ['context' => 'test'])
            ->assertStatus(401)
            ->assertJsonPath('success', false);
    }

    public function test_customer_reply_requires_auth(): void
    {
        $this->postJson('/api/v1/ai/customer-reply', ['context' => 'test'])
            ->assertStatus(401)
            ->assertJsonPath('success', false);
    }

    public function test_analytics_requires_auth(): void
    {
        $this->getJson('/api/v1/ai/analytics')
            ->assertStatus(401)
            ->assertJsonPath('success', false);
    }

    public function test_usage_requires_auth(): void
    {
        $this->getJson('/api/v1/ai/usage')
            ->assertStatus(401)
            ->assertJsonPath('success', false);
    }

    // =========================================================================
    // Client role — blocked on merchant-only endpoints (403)
    // =========================================================================

    public function test_client_cannot_generate_product_description(): void
    {
        $token = $this->clientToken();

        $this->postJson('/api/v1/ai/product-description', ['context' => 'test'], $this->headers($token))
            ->assertStatus(403)
            ->assertJsonPath('success', false);
    }

    public function test_client_cannot_generate_marketing_content(): void
    {
        $token = $this->clientToken();

        $this->postJson('/api/v1/ai/marketing-content', ['context' => 'test'], $this->headers($token))
            ->assertStatus(403)
            ->assertJsonPath('success', false);
    }

    public function test_client_cannot_generate_customer_reply(): void
    {
        $token = $this->clientToken();

        $this->postJson('/api/v1/ai/customer-reply', ['context' => 'test'], $this->headers($token))
            ->assertStatus(403)
            ->assertJsonPath('success', false);
    }

    public function test_client_cannot_access_ai_analytics(): void
    {
        $token = $this->clientToken();

        $this->getJson('/api/v1/ai/analytics', $this->headers($token))
            ->assertStatus(403)
            ->assertJsonPath('success', false);
    }

    // =========================================================================
    // Merchant role — blocked on admin-only endpoints (403)
    // =========================================================================

    public function test_merchant_cannot_access_ai_analytics(): void
    {
        $token = $this->merchantToken();

        $this->getJson('/api/v1/ai/analytics', $this->headers($token))
            ->assertStatus(403)
            ->assertJsonPath('success', false);
    }

    // =========================================================================
    // Admin role — blocked on merchant-only endpoints (403)
    // =========================================================================

    public function test_admin_cannot_access_product_description(): void
    {
        $token = $this->adminToken();

        $this->postJson('/api/v1/ai/product-description', ['context' => 'test'], $this->headers($token))
            ->assertStatus(403)
            ->assertJsonPath('success', false);
    }

    public function test_admin_cannot_access_marketing_content(): void
    {
        $token = $this->adminToken();

        $this->postJson('/api/v1/ai/marketing-content', ['context' => 'test'], $this->headers($token))
            ->assertStatus(403)
            ->assertJsonPath('success', false);
    }

    public function test_admin_cannot_access_customer_reply(): void
    {
        $token = $this->adminToken();

        $this->postJson('/api/v1/ai/customer-reply', ['context' => 'test'], $this->headers($token))
            ->assertStatus(403)
            ->assertJsonPath('success', false);
    }
}
