<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AiUsage extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'service_type',
        'request_count',
        'credits_used',
        'tokens_used',
        'cost_usd',
    ];

    protected function casts(): array
    {
        return [
            'request_count' => 'integer',
            'credits_used'  => 'integer',
            'tokens_used'   => 'integer',
            'cost_usd'      => 'decimal:8',
        ];
    }

    // -------------------------------------------------------------------------
    // Service-type constants — used by services and tests
    // -------------------------------------------------------------------------

    public const TYPE_PRODUCT_DESCRIPTION = 'product_description';
    public const TYPE_MARKETING_CONTENT   = 'marketing_content';
    public const TYPE_CUSTOMER_REPLY      = 'customer_reply';
    public const TYPE_ANALYTICS           = 'analytics';

    public static function validTypes(): array
    {
        return [
            self::TYPE_PRODUCT_DESCRIPTION,
            self::TYPE_MARKETING_CONTENT,
            self::TYPE_CUSTOMER_REPLY,
            self::TYPE_ANALYTICS,
        ];
    }

    // -------------------------------------------------------------------------
    // Relationships
    // -------------------------------------------------------------------------

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
