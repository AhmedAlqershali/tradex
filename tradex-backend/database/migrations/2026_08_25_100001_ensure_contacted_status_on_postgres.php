<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        if (DB::getDriverName() !== 'pgsql') {
            return;
        }

        $constraints = DB::select(<<<'SQL'
            SELECT c.conname
            FROM pg_constraint c
            JOIN pg_class t ON t.oid = c.conrelid
            WHERE t.relname = 'orders'
              AND c.contype = 'c'
              AND pg_get_constraintdef(c.oid) ILIKE '%status%'
        SQL);

        foreach ($constraints as $constraint) {
            $name = str_replace('"', '""', $constraint->conname);
            DB::statement("ALTER TABLE orders DROP CONSTRAINT IF EXISTS \"{$name}\"");
        }

        DB::statement(<<<'SQL'
            ALTER TABLE orders
            ADD CONSTRAINT orders_status_check
            CHECK (status IN ('pending', 'contacted', 'confirmed', 'processing', 'completed', 'cancelled'))
        SQL);
    }

    public function down(): void
    {
        if (DB::getDriverName() !== 'pgsql') {
            return;
        }

        DB::table('orders')->where('status', 'contacted')->update(['status' => 'pending']);
        DB::statement('ALTER TABLE orders DROP CONSTRAINT IF EXISTS orders_status_check');
        DB::statement(<<<'SQL'
            ALTER TABLE orders
            ADD CONSTRAINT orders_status_check
            CHECK (status IN ('pending', 'confirmed', 'processing', 'completed', 'cancelled'))
        SQL);
    }
};