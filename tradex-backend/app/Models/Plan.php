<?php

namespace App\Models;

use Database\Factories\PlanFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Plan extends Model
{
    public const FREE_PLAN_NAME = 'free';
    public const AI_PLAN_NAME = 'ai';
    public const PREMIUM_PLAN_NAME = 'premium';
    public const FREE_MONTHLY_PRICE = 0.00;
    public const FREE_YEARLY_PRICE = 0.00;
    public const AI_MONTHLY_PRICE = 15.00;
    public const AI_YEARLY_PRICE = 180.00;

    /** @use HasFactory<PlanFactory> */
    use HasFactory;

    protected $fillable = [
        'name',
        'display_name',
        'monthly_price',
        'yearly_price',
        'ai_usage_limit',
        'product_limit',
        'store_limit',
        'features',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'monthly_price'  => 'decimal:2',
            'yearly_price'   => 'decimal:2',
            'ai_usage_limit' => 'integer',
            'product_limit'  => 'integer',
            'store_limit'    => 'integer',
            'features'       => 'array',
            'status'         => 'string',
        ];
    }

    // -------------------------------------------------------------------------
    // Relationships
    // -------------------------------------------------------------------------

    public function subscriptions(): HasMany
    {
        return $this->hasMany(Subscription::class);
    }

    public function subscriptionRequests(): HasMany
    {
        return $this->hasMany(SubscriptionRequest::class);
    }

    // -------------------------------------------------------------------------
    // Scopes
    // -------------------------------------------------------------------------

    public function scopeActive($query)
    {
        return $query->where('status', 'active');
    }

    public function isAiPlan(): bool
    {
        return $this->name === self::AI_PLAN_NAME;
    }
}
