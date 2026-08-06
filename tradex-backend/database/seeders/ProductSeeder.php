<?php

namespace Database\Seeders;

use App\Models\Category;
use App\Models\Product;
use App\Models\Store;
use Illuminate\Database\Seeder;

class ProductSeeder extends Seeder
{
    public function run(): void
    {
        $stores     = Store::active()->get();
        $categories = Category::active()->get();

        if ($stores->isEmpty() || $categories->isEmpty()) {
            $this->command->warn('No active stores or categories found — skipping products.');
            return;
        }

        foreach ($stores as $store) {
            // 5–15 products per store
            $count = rand(5, 15);
            Product::factory()
                ->count($count)
                ->forStore($store)
                ->active()
                ->create([
                    'category_id' => $categories->random()->id,
                ]);
        }
    }
}
