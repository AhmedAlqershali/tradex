<?php

namespace Tests\Feature\Console;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class ProvisionAdminCommandTest extends TestCase
{
    use RefreshDatabase;

    public function test_non_production_environment_skips_without_writing(): void
    {
        $this->runWithProvisioningEnvironment([
            'APP_ENV'                 => 'local',
            'DB_CONNECTION'           => 'pgsql',
            'TRADEX_PROVISION_ADMIN'  => 'true',
            'TRADEX_ADMIN_PASSWORD'   => $this->testPassword(),
        ], function (): void {
            $this->artisan('tradex:provision-admin')
                ->expectsOutput('Admin provisioning skipped.')
                ->assertExitCode(0);

            $this->assertDatabaseCount('users', 0);
        });
    }

    public function test_non_postgresql_connection_skips_without_writing(): void
    {
        $this->runWithProvisioningEnvironment([
            'APP_ENV'                 => 'production',
            'DB_CONNECTION'           => 'sqlite',
            'TRADEX_PROVISION_ADMIN'  => 'true',
            'TRADEX_ADMIN_PASSWORD'   => $this->testPassword(),
        ], function (): void {
            $this->artisan('tradex:provision-admin')
                ->expectsOutput('Admin provisioning skipped.')
                ->assertExitCode(0);

            $this->assertDatabaseCount('users', 0);
        });
    }

    public function test_missing_switch_skips_without_writing(): void
    {
        $this->runWithProvisioningEnvironment([
            'APP_ENV'                => 'production',
            'DB_CONNECTION'          => 'pgsql',
            'TRADEX_PROVISION_ADMIN' => null,
            'TRADEX_ADMIN_PASSWORD'  => $this->testPassword(),
        ], function (): void {
            $this->artisan('tradex:provision-admin')
                ->expectsOutput('Admin provisioning skipped.')
                ->assertExitCode(0);

            $this->assertDatabaseCount('users', 0);
        });
    }

    public function test_missing_password_skips_without_writing(): void
    {
        $this->runWithProvisioningEnvironment([
            'APP_ENV'                => 'production',
            'DB_CONNECTION'          => 'pgsql',
            'TRADEX_PROVISION_ADMIN' => 'true',
            'TRADEX_ADMIN_PASSWORD'  => null,
        ], function (): void {
            $this->artisan('tradex:provision-admin')
                ->expectsOutput('Admin provisioning skipped.')
                ->assertExitCode(0);

            $this->assertDatabaseCount('users', 0);
        });
    }

    public function test_existing_admin_is_not_duplicated_or_changed(): void
    {
        $existingPassword = $this->testPassword();
        $admin = User::factory()->admin()->create([
            'email'    => 'admin@tradx.app',
            'password' => Hash::make($existingPassword),
            'status'   => 'active',
        ]);

        $this->runWithProvisioningEnvironment([
            'APP_ENV'                => 'production',
            'DB_CONNECTION'          => 'pgsql',
            'TRADEX_PROVISION_ADMIN' => 'true',
            'TRADEX_ADMIN_PASSWORD'  => $this->testPassword(),
        ], function () use ($admin, $existingPassword): void {
            $this->artisan('tradex:provision-admin')
                ->expectsOutput('Admin already exists.')
                ->assertExitCode(0);

            $admin->refresh();

            $this->assertSame(1, User::query()->count());
            $this->assertSame('admin@tradx.app', $admin->email);
            $this->assertSame('admin', $admin->role);
            $this->assertSame('active', $admin->status);
            $this->assertTrue(Hash::check($existingPassword, $admin->password));
        });
    }

    public function test_guarded_execution_creates_only_the_active_admin(): void
    {
        $adminPassword = $this->testPassword();

        $this->runWithProvisioningEnvironment([
            'APP_ENV'                => 'production',
            'DB_CONNECTION'          => 'pgsql',
            'TRADEX_PROVISION_ADMIN' => 'true',
            'TRADEX_ADMIN_PASSWORD'  => $adminPassword,
        ], function () use ($adminPassword): void {
            $this->artisan('tradex:provision-admin')
                ->expectsOutput('Admin provisioned.')
                ->assertExitCode(0);

            $admin = User::query()->where('email', 'admin@tradx.app')->first();

            $this->assertNotNull($admin);
            $this->assertSame(1, User::query()->count());
            $this->assertSame(1, User::query()->where('role', 'admin')->count());
            $this->assertSame(0, User::query()->where('role', 'client')->count());
            $this->assertSame(0, User::query()->where('role', 'merchant')->count());
            $this->assertSame('admin@tradx.app', $admin->email);
            $this->assertSame('admin', $admin->role);
            $this->assertSame('active', $admin->status);
            $this->assertTrue(Hash::check($adminPassword, $admin->password));
        });
    }

    public function test_running_provisioning_twice_keeps_exactly_one_admin(): void
    {
        $this->runWithProvisioningEnvironment([
            'APP_ENV'                => 'production',
            'DB_CONNECTION'          => 'pgsql',
            'TRADEX_PROVISION_ADMIN' => 'true',
            'TRADEX_ADMIN_PASSWORD'  => $this->testPassword(),
        ], function (): void {
            $this->artisan('tradex:provision-admin')->assertExitCode(0);
            $this->artisan('tradex:provision-admin')
                ->expectsOutput('Admin already exists.')
                ->assertExitCode(0);

            $this->assertSame(1, User::query()->count());
            $this->assertSame(1, User::query()->where('email', 'admin@tradx.app')->count());
        });
    }

    public function test_entrypoint_runs_migrations_before_provisioning_and_starts_after_it(): void
    {
        $entrypoint = file_get_contents(base_path('docker/entrypoint.sh'));

        $this->assertIsString($entrypoint);
        $this->assertLessThan(
            strpos($entrypoint, 'php artisan tradex:provision-admin'),
            strpos($entrypoint, 'php artisan migrate --force --no-interaction')
        );
        $this->assertLessThan(
            strpos($entrypoint, 'php artisan optimize'),
            strpos($entrypoint, 'php artisan tradex:provision-admin')
        );
        $this->assertStringContainsString('exec "$@"', $entrypoint);
    }

    private function testPassword(): string
    {
        return bin2hex(random_bytes(24));
    }

    /**
     * Keep command environment changes isolated while retaining the test DB.
     *
     * @param  array<string, string|null>  $values
     */
    private function runWithProvisioningEnvironment(array $values, \Closure $callback): void
    {
        $originals = [];

        foreach ($values as $key => $value) {
            $originals[$key] = [
                'getenv' => getenv($key),
                'env'    => $_ENV[$key] ?? null,
                'server' => $_SERVER[$key] ?? null,
            ];

            if ($value === null) {
                putenv($key);
                unset($_ENV[$key], $_SERVER[$key]);
            } else {
                putenv($key.'='.$value);
                $_ENV[$key] = $value;
                $_SERVER[$key] = $value;
            }
        }

        try {
            $callback();
        } finally {
            foreach ($originals as $key => $original) {
                if ($original['getenv'] === false) {
                    putenv($key);
                } else {
                    putenv($key.'='.$original['getenv']);
                }

                if ($original['env'] === null) {
                    unset($_ENV[$key]);
                } else {
                    $_ENV[$key] = $original['env'];
                }

                if ($original['server'] === null) {
                    unset($_SERVER[$key]);
                } else {
                    $_SERVER[$key] = $original['server'];
                }
            }
        }
    }
}