<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed order matters — foreign key dependencies must come first.
     *
     *  1. Users       (no FK deps)
     *  2. Categories  (no FK deps)
     *  3. Stores      (depends on users)
     *  4. Products    (depends on stores + categories)
     */
    public function run(): void
    {
        $this->call([
            PlanSeeder::class,
            UserSeeder::class,
            CategorySeeder::class,
            StoreSeeder::class,
            ProductSeeder::class,
        ]);
    }
}
