<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AiRequest extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'service_type',
        'request_payload',
        'response_content',
        'tokens_used',
        'credits_used',
        'cost_usd',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'request_payload' => 'array',
            'tokens_used'     => 'integer',
            'credits_used'    => 'integer',
            'cost_usd'        => 'decimal:8',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}