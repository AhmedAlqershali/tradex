<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('commissions', function (Blueprint $table) {
            $table->string('payment_status')->default('unpaid')->after('status');
            $table->timestamp('paid_at')->nullable()->after('payment_status');
            $table->foreignId('paid_by')->nullable()->constrained('users')->nullOnDelete()->after('paid_at');
            $table->foreignId('recorded_by')->nullable()->constrained('users')->nullOnDelete()->after('paid_by');
            $table->index(['payment_status', 'paid_at']);
        });
    }

    public function down(): void
    {
        Schema::table('commissions', function (Blueprint $table) {
            $table->dropIndex(['payment_status', 'paid_at']);
            $table->dropForeign(['paid_by']);
            $table->dropForeign(['recorded_by']);
            $table->dropColumn(['payment_status', 'paid_at', 'paid_by', 'recorded_by']);
        });
    }
};
