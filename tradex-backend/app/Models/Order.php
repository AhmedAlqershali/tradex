<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Order extends Model
{
    use HasFactory;

    /**
     * Mass-assignable fields.
     *
     * SECURITY: the following fields are intentionally excluded:
     * `client_id`    — set from authenticated user; must not be overridable.
     * `store_id`     — derived from cart items; must not be overridable.
     * `total_amount` — computed server-side from product prices; never trusted from input.
     * `status`       — only the merchant may advance status via a dedicated endpoint.
     *
     * All writes to these fields use `Order::forceCreate()` or direct attribute
     * assignment inside trusted service/repository code.
     */
    protected $fillable = [
        'customer_name',
        'customer_phone',
        'customer_city',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'total_amount' => 'float',
            'status'       => 'string',
        ];
    }

    // Status constants
    const STATUS_PENDING    = 'pending';
    const STATUS_CONFIRMED  = 'confirmed';
    const STATUS_PROCESSING = 'processing';
    const STATUS_COMPLETED  = 'completed';
    const STATUS_CANCELLED  = 'cancelled';

    /** Statuses a merchant may transition to. */
    const MERCHANT_ALLOWED_STATUSES = [
        self::STATUS_CONFIRMED,
        self::STATUS_PROCESSING,
        self::STATUS_COMPLETED,
        self::STATUS_CANCELLED,
    ];

    // -------------------------------------------------------------------------
    // Relationships
    // -------------------------------------------------------------------------

    public function client(): BelongsTo
    {
        return $this->belongsTo(User::class, 'client_id');
    }

    public function store(): BelongsTo
    {
        return $this->belongsTo(Store::class);
    }

    public function items(): HasMany
    {
        return $this->hasMany(OrderItem::class);
    }

    // -------------------------------------------------------------------------
    // Scopes
    // -------------------------------------------------------------------------

    public function scopeForClient($query, int $clientId)
    {
        return $query->where('client_id', $clientId);
    }

    public function scopeForStore($query, int $storeId)
    {
        return $query->where('store_id', $storeId);
    }
}
