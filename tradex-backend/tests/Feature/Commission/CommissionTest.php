<?php

namespace Tests\Feature\Commission;

use App\Models\Commission;
use App\Models\Order;
use App\Models\Store;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CommissionTest extends TestCase
{
    use RefreshDatabase;

    private function merchantHeaders(string $token): array
    {
        return [
            'Authorization' => "Bearer {$token}",
            'Accept' => 'application/json',
        ];
    }

    private function adminHeaders(string $token): array
    {
        return [
            'Authorization' => "Bearer {$token}",
            'Accept' => 'application/json',
        ];
    }

    public function test_order_completion_creates_5_percent_commission(): void
    {
        $merchant = User::factory()->merchant()->create(['status' => 'active']);
        $this->entitleMerchant($merchant);
        $store = Store::factory()->forUser($merchant)->active()->create();
        $token = $merchant->createToken('test')->plainTextToken;
        $order = Order::factory()->forStore($store)->pending()->create([
            'total_amount' => 100.00,
        ]);

        $this->putJson(
            "/api/v1/merchant/orders/{$order->id}/status",
            ['status' => 'confirmed'],
            $this->merchantHeaders($token),
        )->assertOk();

        $this->putJson(
            "/api/v1/merchant/orders/{$order->id}/status",
            ['status' => 'completed'],
            $this->merchantHeaders($token),
        )->assertOk();

        $this->assertDatabaseHas('commissions', [
            'order_id' => $order->id,
            'merchant_id' => $merchant->id,
            'store_id' => $store->id,
            'order_amount' => '100.00',
            'commission_rate' => '5.00',
            'commission_amount' => '5.00',
            'merchant_net_amount' => '95.00',
            'status' => 'accrued',
        ]);

        $this->assertSame(1, Commission::where('order_id', $order->id)->count());
    }

    public function test_order_completion_for_250_amount_uses_12_50_commission(): void
    {
        $merchant = User::factory()->merchant()->create(['status' => 'active']);
        $this->entitleMerchant($merchant);
        $store = Store::factory()->forUser($merchant)->active()->create();
        $token = $merchant->createToken('test')->plainTextToken;
        $order = Order::factory()->forStore($store)->pending()->create([
            'total_amount' => 250.00,
        ]);

        $this->putJson(
            "/api/v1/merchant/orders/{$order->id}/status",
            ['status' => 'confirmed'],
            $this->merchantHeaders($token),
        )->assertOk();

        $this->putJson(
            "/api/v1/merchant/orders/{$order->id}/status",
            ['status' => 'completed'],
            $this->merchantHeaders($token),
        )->assertOk();

        $this->assertDatabaseHas('commissions', [
            'order_id' => $order->id,
            'commission_rate' => '5.00',
            'commission_amount' => '12.50',
            'merchant_net_amount' => '237.50',
        ]);
    }

    public function test_repeated_completion_does_not_create_duplicate_commission(): void
    {
        $merchant = User::factory()->merchant()->create(['status' => 'active']);
        $this->entitleMerchant($merchant);
        $store = Store::factory()->forUser($merchant)->active()->create();
        $token = $merchant->createToken('test')->plainTextToken;
        $order = Order::factory()->forStore($store)->pending()->create([
            'total_amount' => 120.00,
        ]);

        $this->putJson(
            "/api/v1/merchant/orders/{$order->id}/status",
            ['status' => 'confirmed'],
            $this->merchantHeaders($token),
        )->assertOk();

        $this->putJson(
            "/api/v1/merchant/orders/{$order->id}/status",
            ['status' => 'completed'],
            $this->merchantHeaders($token),
        )->assertOk();

        $this->putJson(
            "/api/v1/merchant/orders/{$order->id}/status",
            ['status' => 'completed'],
            $this->merchantHeaders($token),
        )->assertStatus(422);

        $this->assertSame(1, Commission::where('order_id', $order->id)->count());
    }

    public function test_cancelled_order_does_not_create_commission(): void
    {
        $merchant = User::factory()->merchant()->create(['status' => 'active']);
        $this->entitleMerchant($merchant);
        $store = Store::factory()->forUser($merchant)->active()->create();
        $token = $merchant->createToken('test')->plainTextToken;
        $order = Order::factory()->forStore($store)->pending()->create([
            'total_amount' => 80.00,
        ]);

        $this->putJson(
            "/api/v1/merchant/orders/{$order->id}/status",
            ['status' => 'cancelled'],
            $this->merchantHeaders($token),
        )->assertOk();

        $this->assertDatabaseMissing('commissions', [
            'order_id' => $order->id,
        ]);
    }

    public function test_commission_rate_snapshot_is_stored_as_5_percent(): void
    {
        $merchant = User::factory()->merchant()->create(['status' => 'active']);
        $this->entitleMerchant($merchant);
        $store = Store::factory()->forUser($merchant)->active()->create();
        $token = $merchant->createToken('test')->plainTextToken;
        $order = Order::factory()->forStore($store)->pending()->create([
            'total_amount' => 150.00,
        ]);

        $this->putJson(
            "/api/v1/merchant/orders/{$order->id}/status",
            ['status' => 'confirmed'],
            $this->merchantHeaders($token),
        )->assertOk();

        $this->putJson(
            "/api/v1/merchant/orders/{$order->id}/status",
            ['status' => 'completed'],
            $this->merchantHeaders($token),
        )->assertOk();

        $commission = Commission::where('order_id', $order->id)->firstOrFail();
        $this->assertSame('5.00', (string) $commission->commission_rate);
    }

    public function test_admin_can_read_commission_data(): void
    {
        $merchant = User::factory()->merchant()->create(['status' => 'active']);
        $store = Store::factory()->forUser($merchant)->active()->create();
        $order = Order::factory()->forStore($store)->pending()->create([
            'total_amount' => 100.00,
        ]);
        $order->update(['status' => 'completed']);
        Commission::create([
            'order_id' => $order->id,
            'merchant_id' => $merchant->id,
            'store_id' => $store->id,
            'order_amount' => 100.00,
            'commission_rate' => 5.00,
            'commission_amount' => 5.00,
            'merchant_net_amount' => 95.00,
            'status' => 'accrued',
        ]);

        $admin = User::factory()->admin()->create(['status' => 'active']);
        $token = $admin->createToken('test')->plainTextToken;

        $this->getJson('/api/v1/admin/commissions', $this->adminHeaders($token))
            ->assertOk()
            ->assertJsonPath('success', true);
    }

    public function test_admin_can_record_commission_payment_once(): void
    {
        $merchant = User::factory()->merchant()->create(['status' => 'active']);
        $this->entitleMerchant($merchant);
        $store = Store::factory()->forUser($merchant)->active()->create();
        $order = Order::factory()->forStore($store)->pending()->create([
            'total_amount' => 500.00,
        ]);

        $commission = Commission::create([
            'order_id' => $order->id,
            'merchant_id' => $merchant->id,
            'store_id' => $store->id,
            'order_amount' => 500.00,
            'commission_rate' => 5.00,
            'commission_amount' => 25.00,
            'merchant_net_amount' => 475.00,
            'status' => 'accrued',
            'payment_status' => 'unpaid',
        ]);

        $admin = User::factory()->admin()->create(['status' => 'active']);
        $token = $admin->createToken('test')->plainTextToken;

        $this->postJson(
            "/api/v1/admin/commissions/{$commission->id}/mark-paid",
            [],
            $this->adminHeaders($token),
        )
            ->assertOk()
            ->assertJsonPath('data.payment_status', 'paid');

        $commission->refresh();
        $this->assertNotNull($commission->paid_at);
        $this->assertSame($admin->id, $commission->paid_by);
        $this->assertSame($admin->id, $commission->recorded_by);

        $this->postJson(
            "/api/v1/admin/commissions/{$commission->id}/mark-paid",
            [],
            $this->adminHeaders($token),
        )->assertStatus(409);
    }

    public function test_merchant_cannot_access_commission_endpoints(): void
    {
        $merchant = User::factory()->merchant()->create(['status' => 'active']);
        $token = $merchant->createToken('test')->plainTextToken;

        $this->getJson('/api/v1/admin/commissions', $this->merchantHeaders($token))
            ->assertForbidden();
    }
}
