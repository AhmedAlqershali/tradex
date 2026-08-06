<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('plans', function (Blueprint $table) {
            $table->id();
            $table->string('name')->unique(); // slug-like key: free | pro | business
            $table->string('display_name');
            $table->decimal('monthly_price', 10, 2)->default(0);
            $table->decimal('yearly_price', 10, 2)->default(0);

            // Null = unlimited. Enforced by SubscriptionService / future AiUsageService.
            $table->unsignedInteger('ai_usage_limit')->nullable();
            $table->unsignedInteger('product_limit')->nullable();
            $table->unsignedInteger('store_limit')->default(1);

            // Flexible flag bag (e.g. {"priority_support": true}) — avoids a
            // migration every time a new plan toggle is needed.
            $table->json('features')->nullable();

            $table->enum('status', ['active', 'inactive'])->default('active');
            $table->timestamps();

            $table->index('status');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('plans');
    }
};
