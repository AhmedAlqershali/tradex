<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('subscription_requests', function (Blueprint $table) {
            $table->id();

            $table->foreignId('user_id')->constrained()->cascadeOnDelete(); // merchant
            $table->foreignId('plan_id')->constrained()->restrictOnDelete();

            $table->enum('billing_cycle', ['monthly', 'yearly'])->default('monthly');

            // Manual payment proof — no payment gateway involved.
            $table->string('full_name');
            $table->string('phone');
            $table->string('payment_method');
            $table->string('payment_proof_image');
            $table->text('notes')->nullable();

            $table->enum('status', ['pending', 'approved', 'rejected'])->default('pending');
            $table->text('rejection_reason')->nullable();

            // Admin who reviewed the request.
            $table->foreignId('reviewed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('reviewed_at')->nullable();

            $table->timestamps();

            $table->index(['user_id', 'status']);
            $table->index('status');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('subscription_requests');
    }
};
