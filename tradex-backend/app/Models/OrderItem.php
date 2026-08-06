<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class OrderItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'order_id',
        'product_id',
        'product_name',
        'unit_price',
        'quantity',
        'subtotal',
    ];

    protected function casts(): array
    {
        return [
            'unit_price' => 'float',
            'quantity'   => 'integer',
            'subtotal'   => 'float',
        ];
    }

    // -------------------------------------------------------------------------
    // Relationships
    // -------------------------------------------------------------------------

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    /**
     * Nullable — product may have been deleted after the order was placed.
     * The snapshot fields (product_name, unit_price) always hold the truth.
     */
    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class)->withDefault();
    }
}
