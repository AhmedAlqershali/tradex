<?php

namespace Database\Seeders;

use App\Models\Category;
use Illuminate\Database\Seeder;

class CategorySeeder extends Seeder
{
    public function run(): void
    {
        $categories = [
            ['name' => 'Electronics',             'status' => 'active'],
            ['name' => 'Fashion & Clothing',       'status' => 'active'],
            ['name' => 'Home & Kitchen',           'status' => 'active'],
            ['name' => 'Food & Groceries',         'status' => 'active'],
            ['name' => 'Beauty & Personal Care',   'status' => 'active'],
            ['name' => 'Sports & Outdoors',        'status' => 'active'],
            ['name' => 'Toys & Games',             'status' => 'active'],
            ['name' => 'Books & Stationery',       'status' => 'active'],
            ['name' => 'Health & Wellness',        'status' => 'active'],
            ['name' => 'Automotive',               'status' => 'active'],
            ['name' => 'Jewelry & Accessories',    'status' => 'active'],
            ['name' => 'Baby & Kids',              'status' => 'active'],
        ];

        foreach ($categories as $category) {
            Category::updateOrCreate(['name' => $category['name']], $category);
        }
    }
}
