<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ai_requests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('service_type', 50);
            $table->json('request_payload')->nullable();
            $table->longText('response_content')->nullable();
            $table->unsignedInteger('tokens_used')->default(0);
            $table->unsignedInteger('credits_used')->default(1);
            $table->string('status', 20)->default('completed');
            $table->timestamps();

            $table->index(['user_id', 'created_at'], 'ai_requests_user_date');
            $table->index(['user_id', 'service_type'], 'ai_requests_user_type');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ai_requests');
    }
};