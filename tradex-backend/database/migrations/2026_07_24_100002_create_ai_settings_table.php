<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ai_settings', function (Blueprint $table) {
            $table->id();

            // One settings row per user (admin sets these per-user as needed)
            $table->foreignId('user_id')
                ->unique()
                ->constrained()
                ->cascadeOnDelete();

            // null = unlimited for that window
            $table->unsignedInteger('daily_limit')->nullable();
            $table->unsignedInteger('monthly_limit')->nullable();

            // Global kill-switch: set false to block all AI access for this user
            $table->boolean('is_active')->default(true);

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ai_settings');
    }
};
