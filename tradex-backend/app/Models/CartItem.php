<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CartItem extends Model
{
    use HasFactory;

    /**
     * Mass-assignable fields.
     *
     * SECURITY: `cart_id` is excluded — it is set automatically by the
     * HasMany relationship when using `$cart->items()->create(...)`, so
     * it never needs to come from user-supplied data.
     */
    protected $fillable = ['product_id', 'quantity'];

    protected function casts(): array
    {
        return [
            'quantity' => 'integer',
        ];
    }

    // -------------------------------------------------------------------------
    // Relationships
    // -------------------------------------------------------------------------

    public function cart(): BelongsTo
    {
        return $this->belongsTo(Cart::class);
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    /**
     * Current unit price from the product (not a snapshot — cart is live).
     */
    public function getUnitPriceAttribute(): float
    {
        return (float) ($this->product?->price ?? 0);
    }

    public function lineTotal(): float
    {
        return $this->unit_price * $this->quantity;
    }
}
