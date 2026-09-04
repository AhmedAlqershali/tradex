<?php

namespace Tests\Feature\Merchant;

use App\Models\Category;
use App\Models\Product;
use App\Models\Store;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class ProductTest extends TestCase
{
    use RefreshDatabase;

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    private function actingAsMerchant(): array
    {
        $merchant = User::factory()->merchant()->create();
        $this->entitleMerchant($merchant);
        $store    = Store::factory()->forUser($merchant)->active()->create();
        $token    = $merchant->createToken('test')->plainTextToken;

        return compact('merchant', 'store', 'token');
    }

    private function headers(string $token): array
    {
        return [
            'Authorization' => "Bearer {$token}",
            'Accept'        => 'application/json',
        ];
    }

    // =========================================================================
    // Auth / Role Guard
    // =========================================================================

    public function test_unauthenticated_cannot_access_merchant_products(): void
    {
        $this->getJson('/api/v1/merchant/products')
            ->assertStatus(401)
            ->assertJsonPath('success', false);
    }

    public function test_client_cannot_access_merchant_products(): void
    {
        $client = User::factory()->client()->create();
        $token  = $client->createToken('test')->plainTextToken;

        $this->getJson('/api/v1/merchant/products', $this->headers($token))
            ->assertStatus(403)
            ->assertJsonPath('success', false);
    }

    // =========================================================================
    // Index
    // =========================================================================

    public function test_merchant_can_list_own_products(): void
    {
        ['merchant' => $merchant, 'store' => $store, 'token' => $token] = $this->actingAsMerchant();

        Product::factory()->count(3)->forStore($store)->active()->create();

        // Product from another store — must NOT appear
        Product::factory()->create();

        $response = $this->getJson('/api/v1/merchant/products', $this->headers($token));

        $response->assertOk()
                 ->assertJsonPath('success', true)
                 ->assertJsonCount(3, 'data.data');
    }

    public function test_index_supports_search_filter(): void
    {
        ['store' => $store, 'token' => $token] = $this->actingAsMerchant();

        Product::factory()->forStore($store)->create(['name' => 'Red Shoes']);
        Product::factory()->forStore($store)->create(['name' => 'Blue Hat']);

        $this->getJson('/api/v1/merchant/products?search=Red', $this->headers($token))
             ->assertOk()
             ->assertJsonCount(1, 'data.data')
             ->assertJsonPath('data.data.0.name', 'Red Shoes');
    }

    public function test_index_supports_status_filter(): void
    {
        ['store' => $store, 'token' => $token] = $this->actingAsMerchant();

        Product::factory()->forStore($store)->create(['status' => 'active']);
        Product::factory()->forStore($store)->create(['status' => 'inactive']);

        $this->getJson('/api/v1/merchant/products?status=inactive', $this->headers($token))
             ->assertOk()
             ->assertJsonCount(1, 'data.data')
             ->assertJsonPath('data.data.0.status', 'inactive');
    }

    public function test_index_supports_category_filter(): void
    {
        ['store' => $store, 'token' => $token] = $this->actingAsMerchant();

        $cat1 = Category::factory()->create();
        $cat2 = Category::factory()->create();

        Product::factory()->forStore($store)->inCategory($cat1)->create();
        Product::factory()->forStore($store)->inCategory($cat1)->create();
        Product::factory()->forStore($store)->inCategory($cat2)->create();

        $this->getJson("/api/v1/merchant/products?category_id={$cat1->id}", $this->headers($token))
             ->assertOk()
             ->assertJsonCount(2, 'data.data');
    }

    public function test_index_returns_pagination_meta(): void
    {
        ['store' => $store, 'token' => $token] = $this->actingAsMerchant();

        Product::factory()->count(5)->forStore($store)->create();

        $response = $this->getJson('/api/v1/merchant/products?per_page=2', $this->headers($token));

        $response->assertOk()
                 ->assertJsonPath('data.pagination.total', 5)
                 ->assertJsonPath('data.pagination.per_page', 2)
                 ->assertJsonPath('data.pagination.last_page', 3);
    }

    // =========================================================================
    // Store (Create)
    // =========================================================================

    public function test_merchant_can_create_product(): void
    {
        ['store' => $store, 'token' => $token] = $this->actingAsMerchant();
        $category = Category::factory()->create();

        $payload = [
            'store_id'    => $store->id,
            'category_id' => $category->id,
            'name'        => 'Wireless Earbuds',
            'description' => 'Great sound quality.',
            'price'       => 49.99,
            'quantity'    => 100,
            'status'      => 'active',
        ];

        $response = $this->postJson('/api/v1/merchant/products', $payload, $this->headers($token));

        $response->assertStatus(201)
                 ->assertJsonPath('success', true)
                 ->assertJsonPath('data.name', 'Wireless Earbuds')
                 ->assertJsonPath('data.price', 49.99);

        $this->assertDatabaseHas('products', ['name' => 'Wireless Earbuds', 'store_id' => $store->id]);
    }

    public function test_zero_stock_product_is_persisted_as_out_of_stock(): void
    {
        ['store' => $store, 'token' => $token] = $this->actingAsMerchant();

        $response = $this->postJson('/api/v1/merchant/products', [
            'store_id' => $store->id,
            'name' => 'Unavailable Item',
            'price' => 10,
            'quantity' => 0,
            'status' => 'active',
        ], $this->headers($token));

        $response->assertCreated()
            ->assertJsonPath('data.status', 'out_of_stock')
            ->assertJsonPath('data.is_available', false);
        $this->assertDatabaseHas('products', [
            'id' => $response->json('data.id'),
            'status' => 'out_of_stock',
            'quantity' => 0,
        ]);
    }

    public function test_merchant_can_create_product_with_images(): void
    {
        Storage::fake('public');

        ['store' => $store, 'token' => $token] = $this->actingAsMerchant();

        $payload = [
            'store_id' => $store->id,
            'name'     => 'Laptop',
            'price'    => 999.00,
            'quantity' => 10,
            'images'   => [
                UploadedFile::fake()->image('laptop1.jpg'),
                UploadedFile::fake()->image('laptop2.jpg'),
            ],
        ];

        $response = $this->postJson('/api/v1/merchant/products', $payload, $this->headers($token));

        $response->assertStatus(201)
                 ->assertJsonPath('success', true);

        // Two images stored in DB
        $productId = $response->json('data.id');
        $this->assertDatabaseCount('product_images', 2);

        // Primary image field set
        $this->assertDatabaseMissing('products', ['id' => $productId, 'image' => null]);
    }

    public function test_product_is_not_persisted_with_an_image_path_when_storage_fails(): void
    {
        $this->mockProductStorage(false);
        ['store' => $store, 'token' => $token] = $this->actingAsMerchant();

        $response = $this->postJson('/api/v1/merchant/products', [
            'store_id' => $store->id,
            'name' => 'Storage Failure Product',
            'price' => 10,
            'quantity' => 1,
            'images' => [UploadedFile::fake()->image('failed.jpg')],
        ], $this->headers($token));

        $response->assertStatus(500);
        $this->assertDatabaseCount('product_images', 0);
        $this->assertDatabaseHas('products', [
            'name' => 'Storage Failure Product',
            'image' => null,
        ]);
    }

    public function test_product_is_not_persisted_with_a_missing_stored_image(): void
    {
        $this->mockProductStorage('products/missing.jpg', false);
        ['store' => $store, 'token' => $token] = $this->actingAsMerchant();

        $response = $this->postJson('/api/v1/merchant/products', [
            'store_id' => $store->id,
            'name' => 'Missing Image Product',
            'price' => 10,
            'quantity' => 1,
            'images' => [UploadedFile::fake()->image('missing.jpg')],
        ], $this->headers($token));

        $response->assertStatus(500);
        $this->assertDatabaseCount('product_images', 0);
        $this->assertDatabaseHas('products', [
            'name' => 'Missing Image Product',
            'image' => null,
        ]);
    }

    public function test_failed_multi_image_upload_does_not_leave_an_uploaded_path(): void
    {
        Storage::fake('public');
        $disk = \Mockery::mock(Storage::disk('public'))->makePartial();
        $disk->shouldReceive('putFileAs')->twice()->andReturn('products/first.jpg', false);
        $disk->shouldReceive('exists')->once()->with('products/first.jpg')->andReturn(true);
        $disk->shouldReceive('delete')->once()->with('products/first.jpg')->andReturn(true);
        Storage::set('public', $disk);

        ['store' => $store, 'token' => $token] = $this->actingAsMerchant();
        $response = $this->postJson('/api/v1/merchant/products', [
            'store_id' => $store->id,
            'name' => 'Partial Upload Product',
            'price' => 10,
            'quantity' => 1,
            'images' => [
                UploadedFile::fake()->image('first.jpg'),
                UploadedFile::fake()->image('second.jpg'),
            ],
        ], $this->headers($token));

        $response->assertStatus(500);
        $this->assertDatabaseCount('product_images', 0);
        $this->assertDatabaseHas('products', [
            'name' => 'Partial Upload Product',
            'image' => null,
        ]);
    }

    public function test_create_product_fails_validation_without_required_fields(): void
    {
        ['token' => $token] = $this->actingAsMerchant();

        $this->postJson('/api/v1/merchant/products', [], $this->headers($token))
             ->assertStatus(422)
             ->assertJsonPath('success', false);
    }

    public function test_merchant_cannot_create_product_for_another_merchants_store(): void
    {
        ['token' => $token] = $this->actingAsMerchant();

        // A store belonging to a different merchant
        $otherStore = Store::factory()->create();

        $this->postJson('/api/v1/merchant/products', [
            'store_id' => $otherStore->id,
            'name'     => 'Stolen product',
            'price'    => 1.00,
            'quantity' => 1,
        ], $this->headers($token))
             ->assertStatus(422) // store_id Rule::exists fails
             ->assertJsonPath('success', false);
    }

    // =========================================================================
    // Show
    // =========================================================================

    public function test_merchant_can_view_own_product(): void
    {
        ['store' => $store, 'token' => $token] = $this->actingAsMerchant();
        $product = Product::factory()->forStore($store)->create();

        $this->getJson("/api/v1/merchant/products/{$product->id}", $this->headers($token))
             ->assertOk()
             ->assertJsonPath('success', true)
             ->assertJsonPath('data.id', $product->id);
    }

    public function test_merchant_cannot_view_another_merchants_product(): void
    {
        ['token' => $token] = $this->actingAsMerchant();

        $otherProduct = Product::factory()->create();

        $this->getJson("/api/v1/merchant/products/{$otherProduct->id}", $this->headers($token))
             ->assertStatus(404)
             ->assertJsonPath('success', false);
    }

    public function test_show_returns_404_for_nonexistent_product(): void
    {
        ['token' => $token] = $this->actingAsMerchant();

        $this->getJson('/api/v1/merchant/products/99999', $this->headers($token))
             ->assertStatus(404);
    }

    // =========================================================================
    // Update
    // =========================================================================

    public function test_merchant_can_update_own_product(): void
    {
        ['store' => $store, 'token' => $token] = $this->actingAsMerchant();
        $product = Product::factory()->forStore($store)->create(['name' => 'Old Name']);

        $this->putJson("/api/v1/merchant/products/{$product->id}", [
            'name'  => 'New Name',
            'price' => 199.99,
        ], $this->headers($token))
             ->assertOk()
             ->assertJsonPath('success', true)
             ->assertJsonPath('data.name', 'New Name')
             ->assertJsonPath('data.price', 199.99);

        $this->assertDatabaseHas('products', ['id' => $product->id, 'name' => 'New Name']);
    }

    public function test_update_can_clear_nullable_fields_without_changing_omitted_fields(): void
    {
        ['store' => $store, 'token' => $token] = $this->actingAsMerchant();
        $category = Category::factory()->create();
        $product = Product::factory()->forStore($store)->inCategory($category)->create([
            'name'        => 'Keep This Name',
            'description' => 'Remove this description',
        ]);

        $this->putJson("/api/v1/merchant/products/{$product->id}", [
            'category_id' => null,
            'description' => null,
        ], $this->headers($token))
             ->assertOk()
             ->assertJsonPath('data.name', 'Keep This Name')
             ->assertJsonPath('data.category_id', null)
             ->assertJsonPath('data.description', null);

        $this->assertDatabaseHas('products', [
            'id'          => $product->id,
            'name'        => 'Keep This Name',
            'category_id' => null,
            'description' => null,
        ]);
    }

    public function test_merchant_cannot_update_another_merchants_product(): void
    {
        ['token' => $token] = $this->actingAsMerchant();
        $other = Product::factory()->create();

        $this->putJson("/api/v1/merchant/products/{$other->id}", ['name' => 'Hack'], $this->headers($token))
             ->assertStatus(404);
    }

    public function test_update_with_new_images_replaces_existing(): void
    {
        Storage::fake('public');

        ['store' => $store, 'token' => $token] = $this->actingAsMerchant();
        $product = Product::factory()->forStore($store)->create();

        // First, add 1 image
        $this->post("/api/v1/merchant/products/{$product->id}", [
            '_method' => 'PUT',
            'images' => [UploadedFile::fake()->image('first.jpg')],
        ], $this->headers($token))->assertOk();

        $this->assertDatabaseCount('product_images', 1);

        // Replace with 2 new images
        $this->post("/api/v1/merchant/products/{$product->id}", [
            '_method' => 'PUT',
            'images' => [
                UploadedFile::fake()->image('new1.jpg'),
                UploadedFile::fake()->image('new2.jpg'),
            ],
            'clear_images' => true,
        ], $this->headers($token))->assertOk();

        $this->assertDatabaseCount('product_images', 2);
    }

    public function test_update_with_new_images_preserves_existing_by_default(): void
    {
        Storage::fake('public');

        ['store' => $store, 'token' => $token] = $this->actingAsMerchant();
        $product = Product::factory()->forStore($store)->create();

        $this->post("/api/v1/merchant/products/{$product->id}", [
            '_method' => 'PUT',
            'images' => [UploadedFile::fake()->image('existing.jpg')],
        ], $this->headers($token))->assertOk();
        $existingPath = $product->fresh()->image;

        $this->post("/api/v1/merchant/products/{$product->id}", [
            '_method' => 'PUT',
            'images' => [UploadedFile::fake()->image('additional.jpg')],
        ], $this->headers($token))->assertOk();

        $product->refresh();
        $this->assertDatabaseCount('product_images', 2);
        $this->assertSame($existingPath, $product->image);
        Storage::disk('public')->assertExists($existingPath);
    }

    public function test_update_rejects_more_than_ten_total_images_without_changing_existing_images(): void
    {
        Storage::fake('public');

        ['store' => $store, 'token' => $token] = $this->actingAsMerchant();
        $product = Product::factory()->forStore($store)->create();
        $this->post("/api/v1/merchant/products/{$product->id}", [
            '_method' => 'PUT',
            'images' => [UploadedFile::fake()->image('existing.jpg')],
        ], $this->headers($token))->assertOk();

        $existingPath = $product->fresh()->image;
        $tooManyImages = array_map(
            fn (int $index) => UploadedFile::fake()->image("additional-{$index}.jpg"),
            range(1, 10),
        );

        $this->post("/api/v1/merchant/products/{$product->id}", [
            '_method' => 'PUT',
            'images' => $tooManyImages,
        ], $this->headers($token))->assertStatus(422);

        $this->assertDatabaseCount('product_images', 1);
        $this->assertSame($existingPath, $product->fresh()->image);
        Storage::disk('public')->assertExists($existingPath);
    }

    public function test_update_clear_images_removes_all(): void
    {
        Storage::fake('public');

        ['store' => $store, 'token' => $token] = $this->actingAsMerchant();
        $product = Product::factory()->forStore($store)->create();

        // Add image first
        $this->putJson("/api/v1/merchant/products/{$product->id}", [
            'images' => [UploadedFile::fake()->image('img.jpg')],
        ], $this->headers($token));

        $this->assertDatabaseCount('product_images', 1);

        // Clear images
        $this->putJson("/api/v1/merchant/products/{$product->id}", [
            'clear_images' => true,
        ], $this->headers($token))->assertOk();

        $this->assertDatabaseCount('product_images', 0);
        $this->assertDatabaseHas('products', ['id' => $product->id, 'image' => null]);
    }

    private function mockProductStorage(string|false $path, bool $exists = true): void
    {
        Storage::fake('public');

        $disk = \Mockery::mock(Storage::disk('public'))->makePartial();
        $disk->shouldReceive('putFileAs')->once()->andReturn($path);

        if ($path !== false) {
            $disk->shouldReceive('exists')->once()->with($path)->andReturn($exists);
        }

        Storage::set('public', $disk);
    }

    // =========================================================================
    // Destroy
    // =========================================================================

    public function test_merchant_can_delete_own_product(): void
    {
        ['store' => $store, 'token' => $token] = $this->actingAsMerchant();
        $product = Product::factory()->forStore($store)->create();

        $this->deleteJson("/api/v1/merchant/products/{$product->id}", [], $this->headers($token))
             ->assertOk()
             ->assertJsonPath('success', true);

        $this->assertDatabaseMissing('products', ['id' => $product->id]);
    }

    public function test_merchant_cannot_delete_another_merchants_product(): void
    {
        ['token' => $token] = $this->actingAsMerchant();
        $other = Product::factory()->create();

        $this->deleteJson("/api/v1/merchant/products/{$other->id}", [], $this->headers($token))
             ->assertStatus(404);
    }

    public function test_delete_nonexistent_product_returns_404(): void
    {
        ['token' => $token] = $this->actingAsMerchant();

        $this->deleteJson('/api/v1/merchant/products/99999', [], $this->headers($token))
             ->assertStatus(404);
    }

    // =========================================================================
    // Admin
    // =========================================================================

    public function test_admin_can_list_all_products(): void
    {
        // Products from two different stores
        Product::factory()->count(3)->create();

        $admin = User::factory()->admin()->create();
        $token = $admin->createToken('test')->plainTextToken;

        $this->getJson('/api/v1/admin/products', $this->headers($token))
             ->assertOk()
             ->assertJsonPath('success', true)
             ->assertJsonCount(3, 'data.data');
    }

    public function test_admin_can_view_any_product(): void
    {
        $product = Product::factory()->create();

        $admin = User::factory()->admin()->create();
        $token = $admin->createToken('test')->plainTextToken;

        $this->getJson("/api/v1/admin/products/{$product->id}", $this->headers($token))
             ->assertOk()
             ->assertJsonPath('data.id', $product->id);
    }

    public function test_merchant_cannot_access_admin_products_endpoint(): void
    {
        ['token' => $token] = $this->actingAsMerchant();

        $this->getJson('/api/v1/admin/products', $this->headers($token))
             ->assertStatus(403);
    }
}
