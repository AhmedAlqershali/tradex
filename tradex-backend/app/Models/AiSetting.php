<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AiSetting extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'daily_limit',
        'monthly_limit',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'daily_limit'   => 'integer',
            'monthly_limit' => 'integer',
            'is_active'     => 'boolean',
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
