<?php

namespace Tests\Feature\Client;

use App\Models\Order;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class OrderFilterTest extends TestCase
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

    // =========================================================================
    // GET /api/v1/orders?status=... — Status Filtering
    // =========================================================================

    public function test_client_can_filter_orders_by_status_pending_review(): void
    {
        ['client' => $client, 'token' => $token] = $this->actingAsClient();

        Order::factory()->forClient($client)->count(3)->create(['status' => 'pending_review']);
        Order::factory()->forClient($client)->count(2)->create(['status' => 'completed']);

        $this->getJson('/api/v1/orders?status=pending_review', $this->headers($token))
             ->assertOk()
             ->assertJsonPath('data.pagination.total', 3);
    }

    public function test_client_can_filter_orders_by_status_completed(): void
    {
        ['client' => $client, 'token' => $token] = $this->actingAsClient();

        Order::factory()->forClient($client)->count(2)->create(['status' => 'pending_review']);
        Order::factory()->forClient($client)->count(4)->create(['status' => 'completed']);

        $this->getJson('/api/v1/orders?status=completed', $this->headers($token))
             ->assertOk()
             ->assertJsonPath('data.pagination.total', 4);
    }

    public function test_client_can_filter_orders_by_status_cancelled(): void
    {
        ['client' => $client, 'token' => $token] = $this->actingAsClient();

        Order::factory()->forClient($client)->count(2)->create(['status' => 'cancelled']);
        Order::factory()->forClient($client)->count(3)->create(['status' => 'pending_review']);

        $this->getJson('/api/v1/orders?status=cancelled', $this->headers($token))
             ->assertOk()
             ->assertJsonPath('data.pagination.total', 2);
    }

    public function test_invalid_status_filter_is_ignored_returns_all(): void
    {
        ['client' => $client, 'token' => $token] = $this->actingAsClient();

        Order::factory()->forClient($client)->count(3)->create();

        // Invalid status — should be silently ignored, returning all orders
        $this->getJson('/api/v1/orders?status=invalid_status', $this->headers($token))
             ->assertOk()
             ->assertJsonPath('data.pagination.total', 3);
    }

    // =========================================================================
    // GET /api/v1/orders?date_from=...&date_to=... — Date Filtering
    // =========================================================================

    public function test_client_can_filter_orders_by_date_from(): void
    {
        ['client' => $client, 'token' => $token] = $this->actingAsClient();

        Order::factory()->forClient($client)->create([
            'created_at' => now()->subDays(10),
        ]);
        Order::factory()->forClient($client)->create([
            'created_at' => now()->subDays(2),
        ]);
        Order::factory()->forClient($client)->create([
            'created_at' => now(),
        ]);

        $dateFrom = now()->subDays(5)->format('Y-m-d');

        $this->getJson("/api/v1/orders?date_from={$dateFrom}", $this->headers($token))
             ->assertOk()
             ->assertJsonPath('data.pagination.total', 2);
    }

    public function test_client_can_filter_orders_by_date_to(): void
    {
        ['client' => $client, 'token' => $token] = $this->actingAsClient();

        Order::factory()->forClient($client)->create([
            'created_at' => now()->subDays(10),
        ]);
        Order::factory()->forClient($client)->create([
            'created_at' => now()->subDays(3),
        ]);
        Order::factory()->forClient($client)->create([
            'created_at' => now(),
        ]);

        $dateTo = now()->subDays(4)->format('Y-m-d');

        $this->getJson("/api/v1/orders?date_to={$dateTo}", $this->headers($token))
             ->assertOk()
             ->assertJsonPath('data.pagination.total', 1);
    }

    public function test_client_can_filter_orders_by_date_range(): void
    {
        ['client' => $client, 'token' => $token] = $this->actingAsClient();

        Order::factory()->forClient($client)->create(['created_at' => now()->subDays(20)]);
        Order::factory()->forClient($client)->create(['created_at' => now()->subDays(10)]);
        Order::factory()->forClient($client)->create(['created_at' => now()->subDays(5)]);
        Order::factory()->forClient($client)->create(['created_at' => now()]);

        $dateFrom = now()->subDays(12)->format('Y-m-d');
        $dateTo   = now()->subDays(3)->format('Y-m-d');

        $this->getJson("/api/v1/orders?date_from={$dateFrom}&date_to={$dateTo}", $this->headers($token))
             ->assertOk()
             ->assertJsonPath('data.pagination.total', 2);
    }

    public function test_status_and_date_filters_combine(): void
    {
        ['client' => $client, 'token' => $token] = $this->actingAsClient();

        // Pending orders in range
        Order::factory()->forClient($client)->create([
            'status'     => 'pending_review',
            'created_at' => now()->subDays(5),
        ]);

        // Completed orders in range
        Order::factory()->forClient($client)->create([
            'status'     => 'completed',
            'created_at' => now()->subDays(3),
        ]);

        // Pending but out of range
        Order::factory()->forClient($client)->create([
            'status'     => 'pending_review',
            'created_at' => now()->subDays(20),
        ]);

        $dateFrom = now()->subDays(10)->format('Y-m-d');

        $this->getJson("/api/v1/orders?status=pending_review&date_from={$dateFrom}", $this->headers($token))
             ->assertOk()
             ->assertJsonPath('data.pagination.total', 1);
    }

    public function test_filter_only_returns_own_orders(): void
    {
        ['client' => $client, 'token' => $token] = $this->actingAsClient();

        Order::factory()->forClient($client)->count(2)->create(['status' => 'pending_review']);
        // Another client's orders — must not appear
        Order::factory()->count(5)->create(['status' => 'pending_review']);

        $this->getJson('/api/v1/orders?status=pending_review', $this->headers($token))
             ->assertOk()
             ->assertJsonPath('data.pagination.total', 2);
    }
}
