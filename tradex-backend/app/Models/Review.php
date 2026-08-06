<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Review extends Model
{
    use HasFactory;

    /**
     * Mass-assignable fields.
     *
     * SECURITY: `user_id` and `product_id` are excluded from mass-assignment.
     * Both are set explicitly by the service layer from the authenticated user
     * and the validated route parameter, preventing users from submitting
     * reviews on behalf of other users (IDOR / impersonation).
     */
    protected $fillable = [
        'rating',
        'comment',
    ];

    protected function casts(): array
    {
        return [
            'rating' => 'integer',
        ];
    }

    // -------------------------------------------------------------------------
    // Relationships
    // -------------------------------------------------------------------------

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
