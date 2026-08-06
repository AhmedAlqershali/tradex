<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Role-based access control tests.
 *
 * Verifies that role guards reject wrong roles and unauthenticated users
 * on every protected route group. Public endpoints must remain accessible.
 */
class PermissionsTest extends TestCase
{
    use RefreshDatabase;

    // ── Helpers ───────────────────────────────────────────────────────────────

    private function headers(string $token): array
    {
        return ['Authorization' => "Bearer {$token}", 'Accept' => 'application/json'];
    }

    private function tokenFor(string $role): string
    {
        return User::factory()->create(['role' => $role])->createToken('test')->plainTextToken;
    }

    // ── Client-only endpoints ─────────────────────────────────────────────────

    public function test_merchant_cannot_access_client_cart(): void
    {
        $this->getJson('/api/v1/cart', $this->headers($this->tokenFor('merchant')))
            ->assertStatus(403);
    }

    public function test_admin_cannot_access_client_cart(): void
    {
        $this->getJson('/api/v1/cart', $this->headers($this->tokenFor('admin')))
            ->assertStatus(403);
    }

    public function test_unauthenticated_cannot_access_client_cart(): void
    {
        $this->getJson('/api/v1/cart')
            ->assertStatus(401);
    }

    // ── Merchant-only endpoints ───────────────────────────────────────────────

    public function test_client_cannot_access_merchant_products(): void
    {
        $this->getJson('/api/v1/merchant/products', $this->headers($this->tokenFor('client')))
            ->assertStatus(403);
    }

    public function test_admin_cannot_access_merchant_products(): void
    {
        $this->getJson('/api/v1/merchant/products', $this->headers($this->tokenFor('admin')))
            ->assertStatus(403);
    }

    public function test_unauthenticated_cannot_access_merchant_products(): void
    {
        $this->getJson('/api/v1/merchant/products')
            ->assertStatus(401);
    }

    // ── Admin-only endpoints ──────────────────────────────────────────────────

    public function test_client_cannot_access_admin_dashboard(): void
    {
        $this->getJson('/api/v1/admin/dashboard', $this->headers($this->tokenFor('client')))
            ->assertStatus(403);
    }

    public function test_merchant_cannot_access_admin_dashboard(): void
    {
        $this->getJson('/api/v1/admin/dashboard', $this->headers($this->tokenFor('merchant')))
            ->assertStatus(403);
    }

    public function test_unauthenticated_cannot_access_admin_dashboard(): void
    {
        $this->getJson('/api/v1/admin/dashboard')
            ->assertStatus(401);
    }

    public function test_client_cannot_access_admin_users(): void
    {
        $this->getJson('/api/v1/admin/users', $this->headers($this->tokenFor('client')))
            ->assertStatus(403);
    }

    public function test_merchant_cannot_manage_categories(): void
    {
        $this->postJson('/api/v1/admin/categories', ['name' => 'Test'], $this->headers($this->tokenFor('merchant')))
            ->assertStatus(403);
    }

    // ── Public endpoints ──────────────────────────────────────────────────────

    public function test_anyone_can_access_health_check(): void
    {
        $this->getJson('/api/v1/health')->assertOk();
    }

    public function test_anyone_can_browse_products(): void
    {
        $this->getJson('/api/v1/products')->assertOk();
    }

    public function test_anyone_can_browse_categories(): void
    {
        $this->getJson('/api/v1/categories')->assertOk();
    }

    // ── Response envelope consistency ─────────────────────────────────────────

    public function test_public_endpoint_has_success_envelope(): void
    {
        $this->getJson('/api/v1/health')
            ->assertJsonStructure(['success', 'message', 'data']);
    }

    public function test_unauthenticated_error_has_success_envelope(): void
    {
        $this->getJson('/api/v1/auth/me')
            ->assertJsonStructure(['success', 'message'])
            ->assertJsonPath('success', false);
    }

    public function test_forbidden_error_has_success_envelope(): void
    {
        $this->getJson('/api/v1/admin/dashboard', $this->headers($this->tokenFor('client')))
            ->assertJsonStructure(['success', 'message'])
            ->assertJsonPath('success', false);
    }
}
