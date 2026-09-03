<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('categories', function (Blueprint $table) {
            $table->string('name_ar')->nullable()->after('name');
            $table->string('name_en')->nullable()->after('name_ar');
        });

        $translations = [
            'Electronics' => ['إلكترونيات', 'Electronics'],
            'Fashion & Clothing' => ['الأزياء والملابس', 'Fashion & Clothing'],
            'Home & Kitchen' => ['المنزل والمطبخ', 'Home & Kitchen'],
            'Food & Groceries' => ['الأغذية والبقالة', 'Food & Groceries'],
            'Beauty & Personal Care' => ['الجمال والعناية الشخصية', 'Beauty & Personal Care'],
            'Sports & Outdoors' => ['الرياضة والأنشطة الخارجية', 'Sports & Outdoors'],
            'Toys & Games' => ['الألعاب', 'Toys & Games'],
            'Books & Stationery' => ['الكتب والقرطاسية', 'Books & Stationery'],
            'Health & Wellness' => ['الصحة والعافية', 'Health & Wellness'],
            'Automotive' => ['السيارات', 'Automotive'],
            'Jewelry & Accessories' => ['المجوهرات والإكسسوارات', 'Jewelry & Accessories'],
            'Baby & Kids' => ['الأطفال والرضع', 'Baby & Kids'],
        ];

        foreach ($translations as $name => [$nameAr, $nameEn]) {
            DB::table('categories')->where('name', $name)->update([
                'name_ar' => $nameAr,
                'name_en' => $nameEn,
            ]);
        }
    }

    public function down(): void
    {
        Schema::table('categories', function (Blueprint $table) {
            $table->dropColumn(['name_ar', 'name_en']);
        });
    }
};