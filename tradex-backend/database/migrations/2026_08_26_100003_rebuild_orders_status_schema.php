<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    private const CANONICAL_STATUSES = [
        'pending_review',
        'confirmed',
        'completed',
        'cancelled',
    ];

    private const LEGACY_STATUSES = [
        'pending',
        'contacted',
        'merchant_contacted',
        'processing',
        'preparing',
    ];

    public function up(): void
    {
        if (DB::getDriverName() === 'sqlite') {
            $this->rebuildSqliteOrdersTable();

            return;
        }

        // The preceding workflow migration already handles schema changes for
        // MySQL and PostgreSQL. Keep this forward migration SQLite-specific so
        // it does not repeat or broaden those platform changes.
    }

    public function down(): void
    {
        // This migration repairs an already-applied SQLite schema. The prior
        // workflow migration owns the historical downgrade path.
    }

    private function rebuildSqliteOrdersTable(): void
    {
        $orders = DB::table('orders');
        $knownStatuses = array_merge(self::CANONICAL_STATUSES, self::LEGACY_STATUSES);
        $unexpectedStatuses = (clone $orders)
            ->whereNotIn('status', $knownStatuses)
            ->distinct()
            ->pluck('status')
            ->all();

        if ($unexpectedStatuses !== []) {
            throw new RuntimeException(
                'Cannot rebuild orders table with unknown statuses: '
                .implode(', ', $unexpectedStatuses)
            );
        }

        $orderCount = $orders->count();

        // SQLite cannot alter a CHECK constraint or column default in place.
        // Disable dependent foreign-key enforcement only for the transactional
        // table replacement; the order_items foreign key still references the
        // final table name after the replacement.
        Schema::disableForeignKeyConstraints();

        try {
            DB::transaction(function () use ($orderCount) {
                Schema::create('orders_canonical', function (Blueprint $table) {
                    $table->id();
                    $table->foreignId('client_id')->constrained('users')->cascadeOnDelete();
                    $table->foreignId('store_id')->constrained()->cascadeOnDelete();
                    $table->string('customer_name');
                    $table->string('customer_phone');
                    $table->string('customer_city');
                    $table->decimal('total_amount', 10, 2)->default(0);
                    $table->enum('status', self::CANONICAL_STATUSES)
                        ->default('pending_review');
                    $table->text('notes')->nullable();
                    $table->timestamps();
                });

                DB::statement(<<<'SQL'
                    INSERT INTO orders_canonical (
                        id,
                        client_id,
                        store_id,
                        customer_name,
                        customer_phone,
                        customer_city,
                        total_amount,
                        status,
                        notes,
                        created_at,
                        updated_at
                    )
                    SELECT
                        id,
                        client_id,
                        store_id,
                        customer_name,
                        customer_phone,
                        customer_city,
                        total_amount,
                        CASE status
                            WHEN 'pending' THEN 'pending_review'
                            WHEN 'contacted' THEN 'pending_review'
                            WHEN 'merchant_contacted' THEN 'pending_review'
                            WHEN 'processing' THEN 'confirmed'
                            WHEN 'preparing' THEN 'confirmed'
                            ELSE status
                        END,
                        notes,
                        created_at,
                        updated_at
                    FROM orders
                SQL);

                $copiedCount = DB::table('orders_canonical')->count();
                if ($copiedCount !== $orderCount) {
                    throw new RuntimeException(
                        "Orders table rebuild copied {$copiedCount} rows; expected {$orderCount}."
                    );
                }

                Schema::drop('orders');
                Schema::rename('orders_canonical', 'orders');

                Schema::table('orders', function (Blueprint $table) {
                    $table->index(
                        ['client_id', 'status'],
                        'orders_client_id_status_index'
                    );
                    $table->index(
                        ['store_id', 'status'],
                        'orders_store_id_status_index'
                    );
                    $table->index('created_at', 'orders_created_at_index');
                });
            });
        } finally {
            Schema::enableForeignKeyConstraints();
        }
    }
};
