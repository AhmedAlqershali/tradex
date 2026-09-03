<?php

namespace Tests\Feature\AdminWeb;

use App\Models\Store;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class UserManagementTest extends TestCase
{
    use RefreshDatabase;

    public function test_only_active_admins_can_view_users(): void
    {
        $this->get('/admin/users')->assertRedirect(route('admin.login'));

        foreach ([User::factory()->client()->create(), User::factory()->merchant()->create()] as $user) {
            $this->actingAs($user, 'web')->get('/admin/users')->assertForbidden();
        }
    }

    public function test_admin_can_search_and_filter_users(): void
    {
        $admin = User::factory()->admin()->create(['status' => 'active']);
        $client = User::factory()->client()->create(['name' => 'Searchable Client']);
        User::factory()->merchant()->create(['name' => 'Other Account']);

        $this->actingAs($admin, 'web')
            ->get('/admin/users?search=Searchable&role=client')
            ->assertOk()
            ->assertSee($client->name)
            ->assertDontSee('Other Account');
    }

    public function test_admin_can_delete_client_and_merchant_accounts(): void
    {
        $admin = User::factory()->admin()->create(['status' => 'active']);
        $client = User::factory()->client()->create();
        $merchant = User::factory()->merchant()->create();
        Store::factory()->for($merchant)->create();

        $response = $this->actingAs($admin, 'web')->delete(route('admin.users.destroy', $client));
        $response->assertRedirect(route('admin.users.index'));
        $this->assertDatabaseMissing('users', ['id' => $client->id]);

        $this->actingAs($admin, 'web')->delete(route('admin.users.destroy', $merchant));
        $this->assertDatabaseMissing('users', ['id' => $merchant->id]);
        $this->assertDatabaseMissing('stores', ['user_id' => $merchant->id]);
    }

    public function test_admin_cannot_delete_self_or_another_admin(): void
    {
        $admin = User::factory()->admin()->create(['status' => 'active']);
        $otherAdmin = User::factory()->admin()->create();

        $this->actingAs($admin, 'web')->delete(route('admin.users.destroy', $admin))
            ->assertSessionHasErrors('user');
        $this->actingAs($admin, 'web')->delete(route('admin.users.destroy', $otherAdmin))
            ->assertForbidden();
    }
}
