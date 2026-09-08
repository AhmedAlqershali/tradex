<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('commissions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained()->cascadeOnDelete();
            $table->foreignId('merchant_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('store_id')->constrained()->cascadeOnDelete();
            $table->decimal('order_amount', 12, 2);
            $table->decimal('commission_rate', 8, 2)->default(5.00);
            $table->decimal('commission_amount', 12, 2);
            $table->decimal('merchant_net_amount', 12, 2);
            $table->string('status')->default('accrued');
            $table->timestamps();

            $table->unique('order_id');
            $table->index(['merchant_id', 'status']);
            $table->index(['store_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('commissions');
    }
};
