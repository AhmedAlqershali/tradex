<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->foreignId('client_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('store_id')->constrained()->cascadeOnDelete();

            // Customer contact snapshot (denormalised for order history stability)
            $table->string('customer_name');
            $table->string('customer_phone');
            $table->string('customer_city');

            $table->decimal('total_amount', 10, 2)->default(0);
            $table->enum('status', ['pending_review', 'confirmed', 'completed', 'cancelled'])
                  ->default('pending_review');
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->index(['client_id', 'status']);
            $table->index(['store_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('orders');
    }
};
