<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Phase 3 — AI SaaS: monetary cost tracking.
 *
 * Adds a `cost_usd` column to both ai_usages and ai_requests tables so
 * operators can track spend per request, per user, and per period.
 * Stored as DECIMAL(10,8) for sub-cent precision.
 *
 * Cost is populated by the AI provider service at response time using
 * the published per-token pricing for the active model.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('ai_usages', function (Blueprint $table) {
            $table->decimal('cost_usd', 10, 8)->default(0)->after('tokens_used')
                ->comment('Estimated USD cost calculated from provider token pricing.');
        });

        Schema::table('ai_requests', function (Blueprint $table) {
            $table->decimal('cost_usd', 10, 8)->default(0)->after('tokens_used')
                ->comment('Estimated USD cost calculated from provider token pricing.');
        });
    }

    public function down(): void
    {
        Schema::table('ai_usages', function (Blueprint $table) {
            $table->dropColumn('cost_usd');
        });

        Schema::table('ai_requests', function (Blueprint $table) {
            $table->dropColumn('cost_usd');
        });
    }
};
