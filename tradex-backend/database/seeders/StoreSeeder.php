<?php

namespace Database\Seeders;

use App\Models\Store;
use App\Models\User;
use Illuminate\Database\Seeder;

class StoreSeeder extends Seeder
{
    public function run(): void
    {
        $merchants = User::where('role', 'merchant')->get();

        // Create 1–2 stores for each merchant
        foreach ($merchants as $merchant) {
            $count = rand(1, 2);
            Store::factory()->count($count)->forUser($merchant)->active()->create();
        }
    }
}
