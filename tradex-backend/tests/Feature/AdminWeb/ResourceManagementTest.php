<?php

namespace Tests\Feature\AdminWeb;

use App\Models\Category;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use App\Models\Store;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ResourceManagementTest extends TestCase
{
    use RefreshDatabase;

    public function test_resource_pages_require_the_admin_web_session(): void
    {
        foreach ([
            '/admin/orders',
            '/admin/products',
            '/admin/categories',
            '/admin/stores',
            '/admin/subscriptions',
        ] as $path) {
            $this->get($path)->assertRedirect(route('admin.login'));
        }
    }

    public function test_admin_subscriptions_url_redirects_to_the_existing_subscription_section(): void
    {
        $this->actingAs(User::factory()->admin()->create(), 'web')
            ->get('/admin/subscriptions')
            ->assertRedirect(route('admin.merchants.index', ['section' => 'subscriptions']).'#subscriptions');

        $this->followingRedirects()
            ->get('/admin/subscriptions')
            ->assertOk()
            ->assertSee('All merchants')
            ->assertSee('Subscription status reflects the latest entitlement period.')
            ->assertSee('id="subscriptions"', false);
    }

    public function test_non_admin_users_cannot_view_resource_pages(): void
    {
        foreach (['client', 'merchant'] as $role) {
            $user = User::factory()->state(['role' => $role])->create();

            foreach (['/admin/orders', '/admin/products', '/admin/categories', '/admin/stores', '/admin/subscriptions'] as $path) {
                $this->actingAs($user, 'web')->get($path)->assertForbidden();
            }
        }
    }

    public function test_admin_can_filter_and_view_orders_and_apply_existing_status_action(): void
    {
        $admin = User::factory()->admin()->create();
        $client = User::factory()->client()->create(['name' => 'Order Customer']);
        $store = Store::factory()->create(['store_name' => 'Order Store']);
        $order = Order::factory()->forClient($client)->forStore($store)->create([
            'customer_name' => 'Order Customer',
            'status' => Order::STATUS_PENDING,
            'total_amount' => 125.50,
        ]);

        $this->actingAs($admin, 'web')
            ->get('/admin/orders?status=pending')
            ->assertOk()
            ->assertSee('#'.$order->id)
            ->assertSee('Order Customer')
            ->assertSee('Order Store');

        $this->get("/admin/orders/{$order->id}")
            ->assertOk()
            ->assertSee('Status action')
            ->assertSee('125.50');

        $this->put("/admin/orders/{$order->id}/status", ['status' => Order::STATUS_CONFIRMED])
            ->assertRedirect(route('admin.orders.show', $order))
            ->assertSessionHas('status');

        // Admins retain their existing ability to set an allowed status
        // directly; merchant-only sequencing must not restrict this path.
        $this->assertDatabaseHas('orders', [
            'id' => $order->id,
            'status' => Order::STATUS_CONFIRMED,
        ]);
    }

    public function test_invalid_order_status_is_rejected_and_missing_order_is_404(): void
    {
        $admin = User::factory()->admin()->create();

        $this->actingAs($admin, 'web')
            ->put('/admin/orders/999999/status', ['status' => Order::STATUS_CONFIRMED])
            ->assertNotFound();

        $order = Order::factory()->create();

        $this->put("/admin/orders/{$order->id}/status", ['status' => 'not-a-status'])
            ->assertRedirect()
            ->assertSessionHasErrors('status');
    }

    public function test_admin_product_pages_are_read_only_and_use_existing_filters(): void
    {
        $admin = User::factory()->admin()->create();
        $category = Category::factory()->create(['name' => 'Admin Category']);
        $store = Store::factory()->create(['store_name' => 'Admin Store']);
        $product = Product::factory()->forStore($store)->inCategory($category)->create([
            'name' => 'Visible Admin Product',
            'status' => 'active',
        ]);

        $this->actingAs($admin, 'web')
            ->get('/admin/products?search=Visible%20Admin%20Product&category_id='.$category->id)
            ->assertOk()
            ->assertSee('Visible Admin Product')
            ->assertSee('Admin Store')
            ->assertSee('Admin Category');

        $this->get("/admin/products/{$product->id}")
            ->assertOk()
            ->assertSee('Visible Admin Product')
            ->assertSee('Admin product changes are not available');
    }

    public function test_admin_can_create_update_and_delete_categories_using_existing_validation(): void
    {
        $admin = User::factory()->admin()->create();

        $this->actingAs($admin, 'web')
            ->post('/admin/categories', ['name' => 'New Admin Category', 'status' => 'active'])
            ->assertRedirect(route('admin.categories.index'));

        $category = Category::query()->where('name', 'New Admin Category')->firstOrFail();

        $this->put("/admin/categories/{$category->id}", [
            'name' => 'Renamed Admin Category',
            'status' => 'inactive',
        ])->assertRedirect(route('admin.categories.index'));

        $this->assertDatabaseHas('categories', [
            'id' => $category->id,
            'name' => 'Renamed Admin Category',
            'status' => 'inactive',
        ]);

        $this->delete("/admin/categories/{$category->id}")
            ->assertRedirect(route('admin.categories.index'));

        $this->assertDatabaseMissing('categories', ['id' => $category->id]);
    }

    public function test_category_delete_surfaces_existing_service_guard(): void
    {
        $admin = User::factory()->admin()->create();
        $category = Category::factory()->create();
        $product = Product::factory()->create(['category_id' => $category->id]);

        $this->actingAs($admin, 'web')
            ->delete("/admin/categories/{$category->id}")
            ->assertRedirect()
            ->assertSessionHasErrors('category');

        $this->assertDatabaseHas('categories', ['id' => $category->id]);
        $this->assertDatabaseHas('products', ['id' => $product->id]);
    }

    public function test_admin_can_view_stores_and_use_existing_status_validation(): void
    {
        $admin = User::factory()->admin()->create();
        $store = Store::factory()->create(['store_name' => 'Operational Store', 'status' => 'active']);

        $this->actingAs($admin, 'web')
            ->get('/admin/stores?search=Operational')
            ->assertOk()
            ->assertSee('Operational Store');

        $this->get("/admin/stores/{$store->id}")
            ->assertOk()
            ->assertSee('Operational Store');

        $this->put("/admin/stores/{$store->id}/status", ['status' => 'suspended'])
            ->assertRedirect()
            ->assertSessionHas('status');

        $this->assertDatabaseHas('stores', ['id' => $store->id, 'status' => 'suspended']);

        $this->put("/admin/stores/{$store->id}/status", ['status' => 'invalid'])
            ->assertRedirect()
            ->assertSessionHasErrors('status');
    }
}