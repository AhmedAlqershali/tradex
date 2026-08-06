<?php

namespace App\Models;

use Database\Factories\ProductFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Product extends Model
{
    /** @use HasFactory<ProductFactory> */
    use HasFactory;

    /**
     * Mass-assignable fields.
     *
     * SECURITY:
     * `store_id`   — excluded: ownership must be derived from the authenticated
     *                merchant's stores, never supplied by the client directly.
     * `total_sold` — excluded: this counter is incremented by the order system
     *                via raw DB update and must never be user-settable.
     */
    protected $fillable = [
        'category_id',
        'name',
        'description',
        'price',
        'quantity',
        'image',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'price'      => 'decimal:2',
            'quantity'   => 'integer',
            'total_sold' => 'integer',
            'status'     => 'string',
        ];
    }

    // -------------------------------------------------------------------------
    // Relationships
    // -------------------------------------------------------------------------

    public function store(): BelongsTo
    {
        return $this->belongsTo(Store::class);
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    public function images(): HasMany
    {
        return $this->hasMany(ProductImage::class)->orderBy('sort_order');
    }

    public function reviews(): HasMany
    {
        return $this->hasMany(Review::class);
    }

    public function favoritedBy(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'favorites')
            ->withTimestamps();
    }

    // -------------------------------------------------------------------------
    // Scopes
    // -------------------------------------------------------------------------

    public function scopeActive($query)
    {
        return $query->where('status', 'active');
    }

    public function scopeInStock($query)
    {
        return $query->where('quantity', '>', 0);
    }

    public function scopeByCategory($query, int $categoryId)
    {
        return $query->where('category_id', $categoryId);
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    public function isAvailable(): bool
    {
        return $this->status === 'active' && $this->quantity > 0;
    }

    public function isOutOfStock(): bool
    {
        return $this->quantity === 0;
    }
}
