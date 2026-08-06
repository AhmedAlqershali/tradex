<?php

namespace Tests\Feature\Client;

use App\Models\Cart;
use App\Models\CartItem;
use App\Models\Order;
use App\Models\Product;
use App\Models\Store;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class OrderCancellationTest extends TestCase
{
    use RefreshDatabase;

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    private function actingAsClient(): array
    {
        $client = User::factory()->client()->create();
        $token  = $client->createToken('test')->plainTextToken;
        return compact('client', 'token');
    }

    private function headers(string $token): array
    {
        return ['Authorization' => "Bearer {$token}", 'Accept' => 'application/json'];
    }

    private function activeStore(): Store
    {
        $merchant = User::factory()->merchant()->create();
        return Store::factory()->forUser($merchant)->active()->create();
    }

    // =========================================================================
    // DELETE /api/v1/orders/{id} — Cancel Order
    // =========================================================================

    public function test_client_can_cancel_a_pending_order(): void
    {
        ['client' => $client, 'token' => $token] = $this->actingAsClient();

        $order = Order::factory()->forClient($client)->create(['status' => 'pending']);

        $this->deleteJson("/api/v1/orders/{$order->id}", [], $this->headers($token))
             ->assertOk()
             ->assertJsonPath('success', true)
             ->assertJsonPath('data.status', 'cancelled');

        $this->assertDatabaseHas('orders', [
            'id'     => $order->id,
            'status' => 'cancelled',
        ]);
    }

    public function test_client_cannot_cancel_a_confirmed_order(): void
    {
        ['client' => $client, 'token' => $token] = $this->actingAsClient();

        $order = Order::factory()->forClient($client)->create(['status' => 'confirmed']);

        $this->deleteJson("/api/v1/orders/{$order->id}", [], $this->headers($token))
             ->assertStatus(422)
             ->assertJsonPath('success', false);

        $this->assertDatabaseHas('orders', ['id' => $order->id, 'status' => 'confirmed']);
    }

    public function test_client_cannot_cancel_a_processing_order(): void
    {
        ['client' => $client, 'token' => $token] = $this->actingAsClient();

        $order = Order::factory()->forClient($client)->create(['status' => 'processing']);

        $this->deleteJson("/api/v1/orders/{$order->id}", [], $this->headers($token))
             ->assertStatus(422)
             ->assertJsonPath('success', false);
    }

    public function test_client_cannot_cancel_a_completed_order(): void
    {
        ['client' => $client, 'token' => $token] = $this->actingAsClient();

        $order = Order::factory()->forClient($client)->create(['status' => 'completed']);

        $this->deleteJson("/api/v1/orders/{$order->id}", [], $this->headers($token))
             ->assertStatus(422)
             ->assertJsonPath('success', false);
    }

    public function test_client_cannot_cancel_already_cancelled_order(): void
    {
        ['client' => $client, 'token' => $token] = $this->actingAsClient();

        $order = Order::factory()->forClient($client)->create(['status' => 'cancelled']);

        $this->deleteJson("/api/v1/orders/{$order->id}", [], $this->headers($token))
             ->assertStatus(422)
             ->assertJsonPath('success', false);
    }

    public function test_client_cannot_cancel_another_clients_order(): void
    {
        ['token' => $token] = $this->actingAsClient();

        $otherOrder = Order::factory()->create(['status' => 'pending']);

        $this->deleteJson("/api/v1/orders/{$otherOrder->id}", [], $this->headers($token))
             ->assertStatus(404);
    }

    public function test_unauthenticated_cannot_cancel_order(): void
    {
        $order = Order::factory()->create(['status' => 'pending']);

        $this->deleteJson("/api/v1/orders/{$order->id}")
             ->assertStatus(401);
    }

    public function test_merchant_cannot_cancel_client_order(): void
    {
        $merchant = User::factory()->merchant()->create();
        $token    = $merchant->createToken('test')->plainTextToken;

        $order = Order::factory()->create(['status' => 'pending']);

        $this->deleteJson("/api/v1/orders/{$order->id}", [], $this->headers($token))
             ->assertStatus(403);
    }

    public function test_cancel_returns_404_for_nonexistent_order(): void
    {
        ['token' => $token] = $this->actingAsClient();

        $this->deleteJson('/api/v1/orders/99999', [], $this->headers($token))
             ->assertStatus(404);
    }
}
