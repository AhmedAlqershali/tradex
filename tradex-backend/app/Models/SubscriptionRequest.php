<?php

namespace App\Models;

use Database\Factories\SubscriptionRequestFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * A merchant's request to activate (or change to) a plan, paid manually
 * outside the system. Admin reviews the uploaded payment proof and
 * approves or rejects — approval activates a Subscription.
 */
class SubscriptionRequest extends Model
{
    /** @use HasFactory<SubscriptionRequestFactory> */
    use HasFactory;

    protected $fillable = [
        'user_id',
        'plan_id',
        'billing_cycle',
        'full_name',
        'phone',
        'payment_method',
        'payment_proof_image',
        'notes',
        'status',
        'rejection_reason',
        'reviewed_by',
        'reviewed_at',
    ];

    protected function casts(): array
    {
        return [
            'billing_cycle' => 'string',
            'status'        => 'string',
            'reviewed_at'   => 'datetime',
        ];
    }

    // -------------------------------------------------------------------------
    // Relationships
    // -------------------------------------------------------------------------

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function plan(): BelongsTo
    {
        return $this->belongsTo(Plan::class);
    }

    public function reviewer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reviewed_by');
    }

    // -------------------------------------------------------------------------
    // Scopes
    // -------------------------------------------------------------------------

    public function scopePending($query)
    {
        return $query->where('status', 'pending');
    }
}
