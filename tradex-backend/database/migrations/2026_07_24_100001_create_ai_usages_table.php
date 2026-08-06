<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ai_usages', function (Blueprint $table) {
            $table->id();

            $table->foreignId('user_id')
                ->constrained()
                ->cascadeOnDelete();

            // product_description | marketing_content | customer_reply | analytics
            $table->string('service_type', 50);

            // Always 1 per row — kept as a column for aggregation flexibility
            $table->unsignedSmallInteger('request_count')->default(1);

            $table->unsignedInteger('tokens_used')->default(0);

            $table->timestamps();

            // Used by AiUsageService to count daily / monthly usage efficiently
            $table->index(['user_id', 'created_at'],     'ai_usages_user_date');
            $table->index(['user_id', 'service_type'],   'ai_usages_user_type');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ai_usages');
    }
};
