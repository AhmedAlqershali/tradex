<?php

namespace Tests\Feature\AdminWeb;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DatabaseSessionSmokeTest extends TestCase
{
    use RefreshDatabase;

    public function test_web_routes_render_with_the_production_database_session_driver(): void
    {
        config([
            'cache.default' => 'database',
            'session.driver' => 'database',
        ]);

        $this->get('/')->assertOk();
        $this->get('/admin/login')
            ->assertOk()
            ->assertSee('Admin portal');
    }
}