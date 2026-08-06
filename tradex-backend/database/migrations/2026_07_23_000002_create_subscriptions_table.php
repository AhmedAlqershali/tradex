<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('subscriptions', function (Blueprint $table) {
            $table->id();

            // Merchant. No unique constraint — history is preserved:
            // a merchant may have many subscription rows over time
            // (previous ones marked 'cancelled'/'expired' when a new
            // one is activated). "Current plan" = latest active row.
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();

            // Plans in use by a subscription cannot be deleted outright.
            $table->foreignId('plan_id')->constrained()->restrictOnDelete();

            $table->enum('billing_cycle', ['monthly', 'yearly'])->default('monthly');
            $table->enum('status', ['active', 'cancelled', 'expired'])->default('active');

            $table->timestamp('starts_at');
            $table->timestamp('ends_at')->nullable();
            $table->timestamp('cancelled_at')->nullable();

            $table->timestamps();

            $table->index(['user_id', 'status']);
            $table->index(['status', 'ends_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('subscriptions');
    }
};
