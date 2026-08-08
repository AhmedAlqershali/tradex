<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('subscriptions', function (Blueprint $table) {
            // Existing subscription rows represent paid periods. New rows can
            // explicitly distinguish the registration trial from paid access.
            $table->string('type')->default('paid')->after('billing_cycle');
            $table->index(['user_id', 'type', 'status']);
        });
    }

    public function down(): void
    {
        Schema::table('subscriptions', function (Blueprint $table) {
            $table->dropIndex(['user_id', 'type', 'status']);
            $table->dropColumn('type');
        });
    }
};