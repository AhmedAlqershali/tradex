<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('ai_usages', function (Blueprint $table) {
            // One successful AI request consumes one credit by default.
            $table->unsignedInteger('credits_used')->default(1)->after('request_count');
        });
    }

    public function down(): void
    {
        Schema::table('ai_usages', function (Blueprint $table) {
            $table->dropColumn('credits_used');
        });
    }
};