<?php

namespace Tests\Feature\Merchant;

use App\Models\Store;
use App\Models\User;
use App\Contracts\Repositories\StoreRepositoryInterface;
use App\Services\StoreService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

/**
 * Merchant store management API tests.
 */
class StoreTest extends TestCase
{
    use RefreshDatabase;

    private function headers(string $token): array
    {
        return ['Authorization' => "Bearer {$token}", 'Accept' => 'application/json'];
    }

    private function actingAsMerchant(): array
    {
        $merchant = User::factory()->merchant()->create();
        $this->entitleMerchant($merchant);
        $store    = Store::factory()->forUser($merchant)->active()->create();
        $token    = $merchant->createToken('test')->plainTextToken;
        return compact('merchant', 'store', 'token');
    }

    // ── Auth / Role guards ────────────────────────────────────────────────────

    public function test_unauthenticated_cannot_list_merchant_stores(): void
    {
        $this->getJson('/api/v1/merchant/stores')
            ->assertStatus(401);
    }

    public function test_client_cannot_list_merchant_stores(): void
    {
        $client = User::factory()->client()->create();
        $token  = $client->createToken('test')->plainTextToken;

        $this->getJson('/api/v1/merchant/stores', $this->headers($token))
            ->assertStatus(403);
    }

    // ── List stores ───────────────────────────────────────────────────────────

    public function test_merchant_can_list_own_stores(): void
    {
        ['token' => $token] = $this->actingAsMerchant();

        // Stores are returned as a flat collection (no pagination — merchants have few stores)
        $this->getJson('/api/v1/merchant/stores', $this->headers($token))
            ->assertOk()
            ->assertJson(['success' => true])
            ->assertJsonStructure(['data' => [['id', 'store_name']]]);
    }

    public function test_merchant_only_sees_own_stores(): void
    {
        ['token' => $token] = $this->actingAsMerchant();

        // Another merchant with 2 stores
        $other = User::factory()->merchant()->create();
        Store::factory()->forUser($other)->count(2)->create();

        $response = $this->getJson('/api/v1/merchant/stores', $this->headers($token));

        $response->assertOk();
        $this->assertCount(1, $response->json('data'));
    }

    public function test_merchant_can_create_first_store_and_repeating_request_does_not_duplicate_it(): void
    {
        $merchant = User::factory()->merchant()->create();
        $this->entitleMerchant($merchant);
        $token = $merchant->createToken('test')->plainTextToken;

        $first = $this->postJson('/api/v1/merchant/stores', [
            'store_name' => 'Legacy Merchant Store',
            'region'     => 'Gaza',
        ], $this->headers($token))
            ->assertOk()
            ->assertJsonPath('data.store_name', 'Legacy Merchant Store');

        $storeId = $first->json('data.id');

        $this->postJson('/api/v1/merchant/stores', [
            'store_name' => 'A Different Name',
        ], $this->headers($token))
            ->assertOk()
            ->assertJsonPath('data.id', $storeId)
            ->assertJsonPath('data.store_name', 'Legacy Merchant Store');

        $this->assertSame(1, Store::where('user_id', $merchant->id)->count());
    }

    // ── Show store ────────────────────────────────────────────────────────────

    public function test_merchant_can_view_own_store(): void
    {
        ['store' => $store, 'token' => $token] = $this->actingAsMerchant();

        $this->getJson("/api/v1/merchant/stores/{$store->id}", $this->headers($token))
            ->assertOk()
            ->assertJsonPath('data.id', $store->id);
    }

    public function test_merchant_cannot_view_another_merchants_store(): void
    {
        ['token' => $token] = $this->actingAsMerchant();

        $other      = User::factory()->merchant()->create();
        $otherStore = Store::factory()->forUser($other)->active()->create();

        $this->getJson("/api/v1/merchant/stores/{$otherStore->id}", $this->headers($token))
            ->assertStatus(404);
    }

    // ── Update store ──────────────────────────────────────────────────────────

    public function test_merchant_can_update_own_store(): void
    {
        ['store' => $store, 'token' => $token] = $this->actingAsMerchant();

        $this->putJson("/api/v1/merchant/stores/{$store->id}", [
            'store_name'  => 'Updated Store Name',
            'description' => 'New description',
            'phone'       => '0599123456',
        ], $this->headers($token))
            ->assertOk()
            ->assertJsonPath('data.store_name', 'Updated Store Name')
            ->assertJsonPath('data.phone', '0599123456');

        $this->assertDatabaseHas('stores', ['id' => $store->id, 'store_name' => 'Updated Store Name']);
        $this->assertDatabaseHas('users', ['id' => $store->user_id, 'phone' => '0599123456']);
    }

    public function test_merchant_cannot_update_another_merchants_store(): void
    {
        ['token' => $token] = $this->actingAsMerchant();

        $other      = User::factory()->merchant()->create();
        $otherStore = Store::factory()->forUser($other)->active()->create();

        $this->putJson("/api/v1/merchant/stores/{$otherStore->id}", [
            'store_name' => 'Hacked Store',
        ], $this->headers($token))
            ->assertStatus(404);
    }

    public function test_merchant_logo_replacement_keeps_new_file_and_removes_old_file(): void
    {
        Storage::fake('public');
        ['store' => $store, 'token' => $token] = $this->actingAsMerchant();
        Storage::disk('public')->put('logos/old.jpg', 'old');
        $store->update(['logo' => 'logos/old.jpg']);

        $this->post("/api/v1/merchant/stores/{$store->id}/logo", [
            'logo' => UploadedFile::fake()->image('new.jpg'),
        ], $this->headers($token))->assertOk();

        $newPath = $store->fresh()->logo;
        Storage::disk('public')->assertMissing('logos/old.jpg');
        Storage::disk('public')->assertExists($newPath);
    }

    public function test_logo_replacement_removes_new_file_when_database_update_fails(): void
    {
        Storage::fake('public');
        $store = Store::factory()->create(['logo' => 'logos/old.jpg']);
        Storage::disk('public')->put('logos/old.jpg', 'old');

        $repository = $this->mock(StoreRepositoryInterface::class);
        $repository->shouldReceive('updateLogo')
            ->once()
            ->andThrow(new \RuntimeException('database unavailable'));

        $this->expectException(\RuntimeException::class);
        try {
            (new StoreService($repository))->updateStoreLogo(
                $store,
                UploadedFile::fake()->image('new.jpg'),
            );
        } finally {
            Storage::disk('public')->assertExists('logos/old.jpg');
            $this->assertCount(1, Storage::disk('public')->allFiles('logos'));
        }
    }
}
