<?php

namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Hash;

class ProvisionAdmin extends Command
{
    private const ADMIN_EMAIL = 'admin@tradx.app';

    protected $signature = 'tradex:provision-admin';

    protected $description = 'Provision the single production Tradx admin account when explicitly enabled';

    public function handle(): int
    {
        if (! $this->guardsPass()) {
            $this->line('Admin provisioning skipped.');

            return self::SUCCESS;
        }

        if (User::query()->where('email', self::ADMIN_EMAIL)->exists()) {
            $this->line('Admin already exists.');

            return self::SUCCESS;
        }

        $admin = new User;
        $admin->forceFill([
            'name'              => 'Admin',
            'email'             => self::ADMIN_EMAIL,
            'password'          => Hash::make((string) $this->environmentValue('TRADEX_ADMIN_PASSWORD')),
            'role'              => 'admin',
            'status'            => 'active',
            'email_verified_at' => now(),
        ])->save();

        $this->line('Admin provisioned.');

        return self::SUCCESS;
    }

    private function guardsPass(): bool
    {
        $appEnvironment = $this->environmentValue('APP_ENV', config('app.env'));
        $databaseConnection = $this->environmentValue('DB_CONNECTION', config('database.default'));
        $provisioningEnabled = strtolower(trim((string) $this->environmentValue('TRADEX_PROVISION_ADMIN', ''))) === 'true';
        $adminPassword = $this->environmentValue('TRADEX_ADMIN_PASSWORD');

        return $appEnvironment === 'production'
            && $databaseConnection === 'pgsql'
            && $provisioningEnabled
            && is_string($adminPassword)
            && trim($adminPassword) !== '';
    }

    private function environmentValue(string $key, mixed $default = null): mixed
    {
        $value = $_SERVER[$key] ?? $_ENV[$key] ?? getenv($key);

        return $value === false || $value === null ? $default : $value;
    }
}