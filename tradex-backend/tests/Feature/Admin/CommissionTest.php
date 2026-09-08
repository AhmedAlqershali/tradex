<?php

namespace Tests\Feature\Admin;

use App\Models\Commission;
use App\Models\Order;
use App\Models\Store;
use App\Models\User;
use App\Contracts\Services\OrderServiceInterface;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CommissionTest extends TestCase
{
    use RefreshDatabase;

    public function test_completed_order_creates_5_percent_commission_for_100_total(): void
    {
        $merchant = User::factory()->merchant()->create();
        $this->entitleMerchant($merchant);
        $client = User::factory()->client()->create();
        $store = Store::factory()->create(['user_id' => $merchant->id]);

        $order = Order::factory()->forClient($client)->forStore($store)->create([
            'status' => Order::STATUS_PENDING,
            'total_amount' => 100.00,
        ]);

        app(OrderServiceInterface::class)->updateStatus($merchant, $order->id, Order::STATUS_COMPLETED);

        $commission = Commission::query()->where('order_id', $order->id)->firstOrFail();

        $this->assertSame('100.00', (string) $commission->order_amount);
        $this->assertSame('5.00', (string) $commission->commission_rate);
        $this->assertSame('5.00', (string) $commission->commission_amount);
        $this->assertSame('95.00', (string) $commission->merchant_net_amount);
        $this->assertSame('accrued', $commission->status);
    }

    public function test_completed_order_creates_5_percent_commission_for_250_total(): void
    {
        $merchant = User::factory()->merchant()->create();
        $this->entitleMerchant($merchant);
        $client = User::factory()->client()->create();
        $store = Store::factory()->create(['user_id' => $merchant->id]);

        $order = Order::factory()->forClient($client)->forStore($store)->create([
            'status' => Order::STATUS_PENDING,
            'total_amount' => 250.00,
        ]);

        app(OrderServiceInterface::class)->updateStatus($merchant, $order->id, Order::STATUS_COMPLETED);

        $commission = Commission::query()->where('order_id', $order->id)->firstOrFail();

        $this->assertSame('250.00', (string) $commission->order_amount);
        $this->assertSame('5.00', (string) $commission->commission_rate);
        $this->assertSame('12.50', (string) $commission->commission_amount);
        $this->assertSame('237.50', (string) $commission->merchant_net_amount);
    }

    public function test_repeated_completion_does_not_create_duplicate_commissions(): void
    {
        $merchant = User::factory()->merchant()->create();
        $client = User::factory()->client()->create();
        $store = Store::factory()->create(['user_id' => $merchant->id]);

        $order = Order::factory()->forClient($client)->forStore($store)->create([
            'status' => Order::STATUS_PENDING,
            'total_amount' => 100.00,
        ]);

        $service = app(OrderServiceInterface::class);
        $service->updateStatus($merchant, $order->id, Order::STATUS_COMPLETED);
        $service->updateStatus($merchant, $order->id, Order::STATUS_COMPLETED);

        $this->assertSame(1, Commission::query()->where('order_id', $order->id)->count());
    }

    public function test_cancelled_order_does_not_create_commission(): void
    {
        $merchant = User::factory()->merchant()->create();
        $client = User::factory()->client()->create();
        $store = Store::factory()->create(['user_id' => $merchant->id]);

        $order = Order::factory()->forClient($client)->forStore($store)->create([
            'status' => Order::STATUS_PENDING,
            'total_amount' => 100.00,
        ]);

        app(OrderServiceInterface::class)->updateStatus($merchant, $order->id, Order::STATUS_CANCELLED);

        $this->assertDatabaseMissing('commissions', ['order_id' => $order->id]);
    }

    public function test_commission_rate_snapshot_stores_5_percent(): void
    {
        $merchant = User::factory()->merchant()->create();
        $this->entitleMerchant($merchant);
        $client = User::factory()->client()->create();
        $store = Store::factory()->create(['user_id' => $merchant->id]);

        $order = Order::factory()->forClient($client)->forStore($store)->create([
            'status' => Order::STATUS_PENDING,
            'total_amount' => 120.00,
        ]);

        app(OrderServiceInterface::class)->updateStatus($merchant, $order->id, Order::STATUS_COMPLETED);

        $this->assertSame('5.00', Commission::query()->where('order_id', $order->id)->value('commission_rate'));
    }

    public function test_admin_can_read_commission_data(): void
    {
        $admin = User::factory()->admin()->create();
        $merchant = User::factory()->merchant()->create();
        $this->entitleMerchant($merchant);
        $client = User::factory()->client()->create();
        $store = Store::factory()->create(['user_id' => $merchant->id]);

        $order = Order::factory()->forClient($client)->forStore($store)->create([
            'status' => Order::STATUS_PENDING,
            'total_amount' => 100.00,
        ]);

        app(OrderServiceInterface::class)->updateStatus($merchant, $order->id, Order::STATUS_COMPLETED);

        $this->actingAs($admin, 'web')
            ->get('/admin/commissions')
            ->assertOk()
            ->assertSee('Commission')
            ->assertSee((string) $order->id)
            ->assertSee('5.00');
    }

    public function test_merchant_cannot_access_commission_management_screen(): void
    {
        $merchant = User::factory()->merchant()->create();

        $this->actingAs($merchant, 'web')
            ->get('/admin/commissions')
            ->assertRedirect();
    }
}
