<?php

namespace Tests\Feature\Client;

use App\Models\Favorite;
use App\Models\Order;
use App\Models\Product;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DashboardTest extends TestCase
{
    use RefreshDatabase;

    public function test_client_dashboard_returns_only_authenticated_client_counters(): void
    {
        $client = User::factory()->client()->create();
        $otherClient = User::factory()->client()->create();
        $token = $client->createToken('test')->plainTextToken;

        Order::factory()->count(2)->create(['client_id' => $client->id]);
        Order::factory()->create(['client_id' => $otherClient->id]);

        $products = Product::factory()->count(3)->create();
        Favorite::create(['user_id' => $client->id, 'product_id' => $products[0]->id]);
        Favorite::create(['user_id' => $client->id, 'product_id' => $products[1]->id]);
        Favorite::create(['user_id' => $otherClient->id, 'product_id' => $products[2]->id]);

        $this->getJson('/api/v1/client/dashboard', [
            'Authorization' => "Bearer {$token}",
            'Accept' => 'application/json',
        ])
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.orders_count', 2)
            ->assertJsonPath('data.favorites_count', 2);
    }

    public function test_client_dashboard_requires_client_role(): void
    {
        $merchant = User::factory()->merchant()->create();
        $token = $merchant->createToken('test')->plainTextToken;

        $this->getJson('/api/v1/client/dashboard', [
            'Authorization' => "Bearer {$token}",
            'Accept' => 'application/json',
        ])
            ->assertForbidden()
            ->assertJsonPath('data', null);
    }
}