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
    public const STATUS_PENDING   = 'pending_review';
    public const STATUS_CONFIRMED = 'confirmed';
    public const STATUS_COMPLETED = 'completed';
    public const STATUS_CANCELLED = 'cancelled';

    /** Every value allowed in the persisted orders.status column. */
    public const PERSISTED_STATUSES = [
        self::STATUS_PENDING,
        self::STATUS_CONFIRMED,
        self::STATUS_COMPLETED,
        self::STATUS_CANCELLED,
    ];

    /** Statuses a merchant may transition to. */
    const MERCHANT_ALLOWED_STATUSES = [
        self::STATUS_CONFIRMED,
        self::STATUS_COMPLETED,
        self::STATUS_CANCELLED,
    ];

    public static function isValidStatus(string $status): bool
    {
        return in_array($status, self::PERSISTED_STATUSES, true);
    }

    public static function merchantCanTransition(string $from, string $to): bool
    {
        if (! self::isValidStatus($from) || ! self::isValidStatus($to)) {
            return false;
        }

        if ($to === self::STATUS_CANCELLED) {
            return in_array($from, [self::STATUS_PENDING, self::STATUS_CONFIRMED], true);
        }

        return match ($from) {
            self::STATUS_PENDING => $to === self::STATUS_CONFIRMED,
            self::STATUS_CONFIRMED => $to === self::STATUS_COMPLETED,
            default => false,
        };
    }

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
