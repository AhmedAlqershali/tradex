<?php

namespace Tests\Feature\AdminWeb;

use App\Models\Plan;
use App\Models\Subscription;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DashboardTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_login_page_is_public_but_dashboard_requires_admin_session(): void
    {
        $this->get('/admin/login')
            ->assertOk()
            ->assertHeader(
                'Content-Security-Policy',
                "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self' data:"
            )
            ->assertSee('Admin portal');

        $this->get('/admin/dashboard')
            ->assertRedirect(route('admin.login'));
    }

    public function test_client_and_merchant_credentials_are_rejected_by_admin_login(): void
    {
        foreach (['client', 'merchant'] as $role) {
            $user = User::factory()->state(['role' => $role])->create([
                'email' => "{$role}@example.com",
            ]);

            $this->from('/admin/login')
                ->post('/admin/login', [
                    'email' => $user->email,
                    'password' => 'password',
                ])
                ->assertRedirect('/admin/login')
                ->assertSessionHasErrors('email');

            $this->assertGuest('web');
        }
    }

    public function test_active_admin_can_login_and_view_live_dashboard_statistics(): void
    {
        $admin = User::factory()->admin()->create([
            'email' => 'admin@example.com',
        ]);
        User::factory()->client()->create();
        $activeMerchant = User::factory()->merchant()->create();
        User::factory()->merchant()->create(['status' => 'inactive']);

        Subscription::factory()->forUser($activeMerchant)->create([
            'type' => 'trial',
            'ends_at' => now()->addDays(10),
        ]);

        $this->post('/admin/login', [
            'email' => $admin->email,
            'password' => 'password',
        ])->assertRedirect(route('admin.dashboard'));

        $this->get('/admin/dashboard')
            ->assertOk()
            ->assertSee('Total users')
            ->assertSee('Total merchants')
            ->assertSee('Active subscriptions')
            ->assertSee('3')
            ->assertSee('1 active trials');
    }

    public function test_admin_navigation_links_to_each_dashboard_module(): void
    {
        $admin = User::factory()->admin()->create();

        $this->actingAs($admin, 'web')
            ->get('/admin/dashboard')
            ->assertOk()
            ->assertSee('href="'.route('admin.dashboard').'"', false)
            ->assertSee('href="'.route('admin.merchants.index').'"', false)
            ->assertSee('href="'.route('admin.merchants.index').'#subscriptions"', false)
            ->assertSee('href="'.route('admin.orders.index').'"', false)
            ->assertSee('href="'.route('admin.products.index').'"', false)
            ->assertSee('href="'.route('admin.categories.index').'"', false)
            ->assertSee('href="'.route('admin.stores.index').'"', false)
            ->assertSee('>Merchants<', false)
            ->assertSee('>Subscriptions<', false)
            ->assertSee('>Stores<', false);
    }

    public function test_inactive_admin_cannot_login(): void
    {
        $admin = User::factory()->admin()->create([
            'status' => 'inactive',
        ]);

        $this->from('/admin/login')
            ->post('/admin/login', [
                'email' => $admin->email,
                'password' => 'password',
            ])
            ->assertRedirect('/admin/login')
            ->assertSessionHasErrors('email');
    }

    public function test_logout_ends_admin_session(): void
    {
        $admin = User::factory()->admin()->create();

        $response = $this->actingAs($admin, 'web')
            ->post('/admin/logout');
        $response
            ->assertRedirect(route('admin.login'));

        $this->get('/admin/dashboard')
            ->assertRedirect(route('admin.login'));
    }
}