<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Add missing performance indexes that were not included in the original migrations.
 *
 * We use Schema::hasIndex() guards so this migration is idempotent — safe
 * to run even if an index was already created by a partial run.
 */
return new class extends Migration
{
    /** Indexes to create: [table, column(s), name] */
    private array $indexes = [
        // products — sorting and search
        ['products',               'created_at',  'products_created_at_index'],
        ['products',               'total_sold',   'products_total_sold_index'],
        ['products',               'name',         'products_name_index'],
        // orders — date-range filters and default sort
        ['orders',                 'created_at',   'orders_created_at_index'],
        // order_items — join / restore-stock lookups
        ['order_items',            'order_id',     'order_items_order_id_index'],
        ['order_items',            'product_id',   'order_items_product_id_index'],
        // users — admin list filters and sort
        ['users',                  'role',         'users_role_index'],
        ['users',                  'status',       'users_status_index'],
        ['users',                  'created_at',   'users_created_at_index'],
        // stores — admin list filters and sort
        ['stores',                 'status',       'stores_status_index'],
        ['stores',                 'created_at',   'stores_created_at_index'],
        // subscription_requests — admin review sort
        ['subscription_requests',  'reviewed_at',  'subscription_requests_reviewed_at_index'],
    ];

    public function up(): void
    {
        foreach ($this->indexes as [$table, $column, $name]) {
            if (! Schema::hasIndex($table, $name)) {
                Schema::table($table, function (Blueprint $t) use ($column, $name) {
                    $t->index($column, $name);
                });
            }
        }
    }

    public function down(): void
    {
        foreach ($this->indexes as [$table, $column, $name]) {
            if (Schema::hasIndex($table, $name)) {
                Schema::table($table, function (Blueprint $t) use ($name) {
                    $t->dropIndex($name);
                });
            }
        }
    }
};
