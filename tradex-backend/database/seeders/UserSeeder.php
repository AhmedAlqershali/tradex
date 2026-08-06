<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    public function run(): void
    {
        // ── Fixed admin account ──────────────────────────────────────────────
        User::updateOrCreate(
            ['email' => 'admin@tradx.app'],
            [
                'name'              => 'Admin',
                'phone'             => '+966 500 000 000',
                'password'          => Hash::make('password'),
                'role'              => 'admin',
                'email_verified_at' => now(),
            ]
        );

        // ── Fixed merchant accounts ──────────────────────────────────────────
        $merchants = [
            ['name' => 'Ahmed Al-Rashid',  'email' => 'merchant1@tradx.app', 'phone' => '+966 511 111 111'],
            ['name' => 'Fatima Al-Zahra',  'email' => 'merchant2@tradx.app', 'phone' => '+966 522 222 222'],
            ['name' => 'Omar Hassan',       'email' => 'merchant3@tradx.app', 'phone' => '+966 533 333 333'],
        ];

        foreach ($merchants as $data) {
            User::updateOrCreate(
                ['email' => $data['email']],
                array_merge($data, [
                    'password'          => Hash::make('password'),
                    'role'              => 'merchant',
                    'email_verified_at' => now(),
                ])
            );
        }

        // ── Fixed client accounts ────────────────────────────────────────────
        $clients = [
            ['name' => 'Sara Al-Mutairi', 'email' => 'client1@tradx.app', 'phone' => '+966 544 444 444'],
            ['name' => 'Khalid Nasser',   'email' => 'client2@tradx.app', 'phone' => '+966 555 555 555'],
        ];

        foreach ($clients as $data) {
            User::updateOrCreate(
                ['email' => $data['email']],
                array_merge($data, [
                    'password'          => Hash::make('password'),
                    'role'              => 'client',
                    'email_verified_at' => now(),
                ])
            );
        }

        // ── Random users ─────────────────────────────────────────────────────
        User::factory()->merchant()->count(7)->create();
        User::factory()->client()->count(10)->create();
    }
}
