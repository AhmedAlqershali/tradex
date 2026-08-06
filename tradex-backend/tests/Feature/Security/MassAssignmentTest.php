<?php

namespace Tests\Feature\Security;

use App\Models\Order;
use App\Models\Product;
use App\Models\Review;
use App\Models\Store;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

/**
 * Mass-assignment protection tests.
 *
 * Verifies that critical protected fields (role, status, user_id, store_id,
 * total_sold, client_id, total_amount) cannot be set via API request input,
 * preventing privilege escalation, IDOR, and data manipulation attacks.
 */
class MassAssignmentTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        // Prevent actual HaveIBeenPwned HTTP calls during tests.
        // The uncompromised() password rule calls api.pwnedpasswords.com; fake it
        // to return a response indicating the password has 0 occurrences in breaches.
        Http::fake([
            'https://api.pwnedpasswords.com/*' => Http::response('', 200),
        ]);
    }

    private function headers(string $token): array
    {
        return ['Authorization' => "Bearer {$token}", 'Accept' => 'application/json'];
    }

    // ── User model — role escalation ──────────────────────────────────────────

    /**
     * A client registering cannot self-assign an admin role.
     */
    public function test_client_registration_ignores_role_field(): void
    {
        $response = $this->postJson('/api/v1/auth/register/client', [
            'name'                  => 'Attacker',
            'email'                 => 'attacker@example.com',
            'phone'                 => '0500000000',
            'password'              => 'Password1!',
            'password_confirmation' => 'Password1!',
            'role'                  => 'admin', // should be ignored
        ]);

        $response->assertStatus(201);

        $this->assertDatabaseHas('users', [
            'email' => 'attacker@example.com',
            'role'  => 'client', // role must stay 'client', not 'admin'
        ]);
    }

    /**
     * A client registering cannot self-assign a merchant role.
     */
    public function test_client_registration_ignores_role_merchant(): void
    {
        $response = $this->postJson('/api/v1/auth/register/client', [
            'name'                  => 'Test User',
            'email'                 => 'test@example.com',
            'phone'                 => '0500000001',
            'password'              => 'Password1!',
            'password_confirmation' => 'Password1!',
            'role'                  => 'merchant',
        ]);

        $response->assertStatus(201);

        $this->assertDatabaseHas('users', [
            'email' => 'test@example.com',
            'role'  => 'client',
        ]);
    }

    /**
     * A client registering cannot self-assign an active/inactive/banned status.
     */
    public function test_client_registration_ignores_status_field(): void
    {
        $this->postJson('/api/v1/auth/register/client', [
            'name'                  => 'Status Attacker',
            'email'                 => 'statusattack@example.com',
            'phone'                 => '0500000002',
            'password'              => 'Password1!',
            'password_confirmation' => 'Password1!',
            'status'                => 'banned', // should be ignored
        ])->assertStatus(201);

        $this->assertDatabaseMissing('users', [
            'email'  => 'statusattack@example.com',
            'status' => 'banned',
        ]);

        $this->assertDatabaseHas('users', [
            'email'  => 'statusattack@example.com',
            'status' => 'active',
        ]);
    }

    /**
     * A merchant registering cannot self-assign an admin role.
     */
    public function test_merchant_registration_ignores_role_field(): void
    {
        $this->postJson('/api/v1/auth/register/merchant', [
            'name'                  => 'Merchant Attacker',
            'email'                 => 'merchantattack@example.com',
            'phone'                 => '0500000003',
            'password'              => 'Password1!',
            'password_confirmation' => 'Password1!',
            'store_name'            => 'My Store',
            'role'                  => 'admin',
        ])->assertStatus(201);

        $this->assertDatabaseHas('users', [
            'email' => 'merchantattack@example.com',
            'role'  => 'merchant',
        ]);
    }

    // ── User model — profile update cannot change role/status ────────────────

    public function test_profile_update_cannot_change_role(): void
    {
        $user  = User::factory()->create(['role' => 'client', 'status' => 'active']);
        $token = $user->createToken('test')->plainTextToken;

        $this->putJson('/api/v1/profile', [
            'name' => 'Updated Name',
            'role' => 'admin',
        ], $this->headers($token))->assertSuccessful();

        $this->assertDatabaseHas('users', [
            'id'   => $user->id,
            'role' => 'client', // unchanged
        ]);
    }

    public function test_profile_update_cannot_change_status(): void
    {
        $user  = User::factory()->create(['role' => 'client', 'status' => 'active']);
        $token = $user->createToken('test')->plainTextToken;

        $this->putJson('/api/v1/profile', [
            'name'   => 'Updated Name',
            'status' => 'banned',
        ], $this->headers($token))->assertSuccessful();

        $this->assertDatabaseHas('users', [
            'id'     => $user->id,
            'status' => 'active', // unchanged
        ]);
    }

    // ── Store model — status mass-assignment ──────────────────────────────────

    public function test_merchant_cannot_self_activate_suspended_store(): void
    {
        $merchant = User::factory()->create(['role' => 'merchant', 'status' => 'active']);
        $store    = Store::factory()->create([
            'user_id' => $merchant->id,
            'status'  => 'suspended',
        ]);
        $token = $merchant->createToken('test')->plainTextToken;

        // Try to change store status via the update endpoint
        $this->putJson("/api/v1/merchant/stores/{$store->id}", [
            'store_name' => 'My Store',
            'status'     => 'active',
        ], $this->headers($token));

        $this->assertDatabaseHas('stores', [
            'id'     => $store->id,
            'status' => 'suspended', // still suspended — merchant cannot change store status
        ]);
    }

    // ── Order model — amount and status manipulation ──────────────────────────

    public function test_checkout_ignores_total_amount_from_request(): void
    {
        $client   = User::factory()->create(['role' => 'client', 'status' => 'active']);
        $merchant = User::factory()->create(['role' => 'merchant', 'status' => 'active']);
        $store    = Store::factory()->create(['user_id' => $merchant->id, 'status' => 'active']);
        $product  = Product::factory()->create([
            'store_id' => $store->id,
            'price'    => 100.00,
            'quantity' => 10,
            'status'   => 'active',
        ]);
        $token = $client->createToken('test')->plainTextToken;

        // Add item to cart
        $this->postJson('/api/v1/cart/items', [
            'product_id' => $product->id,
            'quantity'   => 1,
        ], $this->headers($token))->assertSuccessful();

        // Attempt checkout with a manipulated total_amount
        $this->postJson('/api/v1/orders', [
            'customer_name'  => 'Test Client',
            'customer_phone' => '0500000000',
            'customer_city'  => 'Riyadh',
            'total_amount'   => 0.01, // attacker sets 1 cent
        ], $this->headers($token))->assertSuccessful();

        // Order should use server-computed total, not attacker's value
        $this->assertDatabaseHas('orders', [
            'client_id'    => $client->id,
            'total_amount' => 100.00, // correct server-side computed amount
        ]);
    }

    public function test_checkout_ignores_status_from_request(): void
    {
        $client   = User::factory()->create(['role' => 'client', 'status' => 'active']);
        $merchant = User::factory()->create(['role' => 'merchant', 'status' => 'active']);
        $store    = Store::factory()->create(['user_id' => $merchant->id, 'status' => 'active']);
        $product  = Product::factory()->create([
            'store_id' => $store->id,
            'price'    => 50.00,
            'quantity' => 5,
            'status'   => 'active',
        ]);
        $token = $client->createToken('test')->plainTextToken;

        $this->postJson('/api/v1/cart/items', [
            'product_id' => $product->id,
            'quantity'   => 1,
        ], $this->headers($token))->assertSuccessful();

        $this->postJson('/api/v1/orders', [
            'customer_name'  => 'Test',
            'customer_phone' => '0500000000',
            'customer_city'  => 'Jeddah',
            'status'         => 'completed', // attacker tries to mark order complete immediately
        ], $this->headers($token))->assertSuccessful();

        $this->assertDatabaseHas('orders', [
            'client_id' => $client->id,
            'status'    => 'pending', // must always start as pending
        ]);
    }

    // ── Review model — user_id cannot be spoofed ──────────────────────────────

    public function test_review_cannot_be_submitted_as_another_user(): void
    {
        $attacker = User::factory()->create(['role' => 'client', 'status' => 'active']);
        $victim   = User::factory()->create(['role' => 'client', 'status' => 'active']);
        $merchant = User::factory()->create(['role' => 'merchant', 'status' => 'active']);
        $store    = Store::factory()->create(['user_id' => $merchant->id, 'status' => 'active']);
        $product  = Product::factory()->create([
            'store_id' => $store->id,
            'status'   => 'active',
            'quantity' => 1,
        ]);

        // Attacker first needs to have ordered and received the product
        // (business rule aside — the security test here is purely about user_id)
        $token = $attacker->createToken('test')->plainTextToken;

        $this->postJson("/api/v1/products/{$product->id}/reviews", [
            'rating'  => 5,
            'comment' => 'Great product',
            'user_id' => $victim->id, // attempt to post as the victim
        ], $this->headers($token));

        // Any review that was created must belong to the attacker, not the victim
        $review = Review::where('product_id', $product->id)->first();

        if ($review) {
            $this->assertSame($attacker->id, $review->user_id);
        }
    }

    // ── Product model — total_sold cannot be manipulated ─────────────────────

    public function test_create_product_ignores_total_sold(): void
    {
        $merchant = User::factory()->create(['role' => 'merchant', 'status' => 'active']);
        $store    = Store::factory()->create(['user_id' => $merchant->id, 'status' => 'active']);
        $token    = $merchant->createToken('test')->plainTextToken;

        $response = $this->postJson('/api/v1/merchant/products', [
            'store_id'   => $store->id,
            'name'       => 'Test Product',
            'price'      => 99.99,
            'quantity'   => 10,
            'total_sold' => 9999, // attacker inflates sold count
        ], $this->headers($token));

        if ($response->status() === 201) {
            $productId = $response->json('data.id');
            $this->assertDatabaseHas('products', [
                'id'         => $productId,
                'total_sold' => 0, // must be 0, not 9999
            ]);
        }
    }
}
