<?php

namespace Database\Seeders;

use App\Models\Category;
use Illuminate\Database\Seeder;

class CategorySeeder extends Seeder
{
    public function run(): void
    {
        $categories = [
            ['name' => 'Electronics', 'name_ar' => 'إلكترونيات', 'name_en' => 'Electronics', 'status' => 'active'],
            ['name' => 'Fashion & Clothing', 'name_ar' => 'الأزياء والملابس', 'name_en' => 'Fashion & Clothing', 'status' => 'active'],
            ['name' => 'Home & Kitchen', 'name_ar' => 'المنزل والمطبخ', 'name_en' => 'Home & Kitchen', 'status' => 'active'],
            ['name' => 'Food & Groceries', 'name_ar' => 'الأغذية والبقالة', 'name_en' => 'Food & Groceries', 'status' => 'active'],
            ['name' => 'Beauty & Personal Care', 'name_ar' => 'الجمال والعناية الشخصية', 'name_en' => 'Beauty & Personal Care', 'status' => 'active'],
            ['name' => 'Sports & Outdoors', 'name_ar' => 'الرياضة والأنشطة الخارجية', 'name_en' => 'Sports & Outdoors', 'status' => 'active'],
            ['name' => 'Toys & Games', 'name_ar' => 'الألعاب', 'name_en' => 'Toys & Games', 'status' => 'active'],
            ['name' => 'Books & Stationery', 'name_ar' => 'الكتب والقرطاسية', 'name_en' => 'Books & Stationery', 'status' => 'active'],
            ['name' => 'Health & Wellness', 'name_ar' => 'الصحة والعافية', 'name_en' => 'Health & Wellness', 'status' => 'active'],
            ['name' => 'Automotive', 'name_ar' => 'السيارات', 'name_en' => 'Automotive', 'status' => 'active'],
            ['name' => 'Jewelry & Accessories', 'name_ar' => 'المجوهرات والإكسسوارات', 'name_en' => 'Jewelry & Accessories', 'status' => 'active'],
            ['name' => 'Baby & Kids', 'name_ar' => 'الأطفال والرضع', 'name_en' => 'Baby & Kids', 'status' => 'active'],
        ];

        foreach ($categories as $category) {
            Category::updateOrCreate(['name' => $category['name']], $category);
        }
    }
}
