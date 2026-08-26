<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        $driver = DB::getDriverName();

        if ($driver === 'pgsql') {
            DB::statement('ALTER TABLE orders DROP CONSTRAINT IF EXISTS orders_status_check');
        }

        // Convert every status used by the former merchant workflow without
        // deleting orders. Contact-related values never represented delivery
        // progress, while preparation values had already passed confirmation.
        DB::table('orders')->whereIn('status', ['pending', 'contacted', 'merchant_contacted'])->update([
            'status' => 'pending_review',
        ]);
        DB::table('orders')->whereIn('status', ['processing', 'preparing'])->update([
            'status' => 'confirmed',
        ]);

        if ($driver === 'mysql') {
            DB::statement(
                "ALTER TABLE orders MODIFY status ENUM('pending_review', 'confirmed', 'completed', 'cancelled') NOT NULL DEFAULT 'pending_review'"
            );
        } elseif ($driver === 'pgsql') {
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
                CHECK (status IN ('pending_review', 'confirmed', 'completed', 'cancelled'))
            SQL);
        } elseif ($driver === 'sqlite') {
            // SQLite stores Laravel enum columns as text; the data migration
            // above is sufficient for the local/test database.
        }
    }

    public function down(): void
    {
        $driver = DB::getDriverName();

        if ($driver === 'pgsql') {
            DB::statement('ALTER TABLE orders DROP CONSTRAINT IF EXISTS orders_status_check');
        }

        DB::table('orders')->where('status', 'pending_review')->update([
            'status' => 'pending',
        ]);

        if ($driver === 'mysql') {
            DB::statement(
                "ALTER TABLE orders MODIFY status ENUM('pending', 'contacted', 'confirmed', 'processing', 'completed', 'cancelled') NOT NULL DEFAULT 'pending'"
            );
        } elseif ($driver === 'pgsql') {
            DB::statement(<<<'SQL'
                ALTER TABLE orders
                ADD CONSTRAINT orders_status_check
                CHECK (status IN ('pending', 'contacted', 'confirmed', 'processing', 'completed', 'cancelled'))
            SQL);
        }
    }
};