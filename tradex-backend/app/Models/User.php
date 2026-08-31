<?php

namespace App\Models;

use App\Notifications\QueuedVerifyEmail;
use Database\Factories\UserFactory;
use Illuminate\Auth\MustVerifyEmail as MustVerifyEmailTrait;
use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use App\Models\AiUsage;
use App\Models\AiSetting;
use App\Models\AiRequest;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable implements MustVerifyEmail
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable, MustVerifyEmailTrait;

    /**
     * Mass-assignable fields.
     *
     * SECURITY: `role` and `status` are intentionally excluded.
     * They must be set explicitly in service code via `forceFill` / direct
     * attribute assignment to prevent privilege escalation through mass-assignment.
     */
    protected $fillable = [
        'name',
        'email',
        'phone',
        'region',
        'location_name',
        'latitude',
        'longitude',
        'password',
        'avatar',
    ];

    /**
     * Fields that must never appear in serialised user payloads.
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password'          => 'hashed',
            'status'            => 'string',
            'latitude'          => 'float',
            'longitude'         => 'float',
        ];
    }

    // -------------------------------------------------------------------------
    // Relationships
    // -------------------------------------------------------------------------

    public function stores(): HasMany
    {
        return $this->hasMany(Store::class);
    }

    public function orders(): HasMany
    {
        return $this->hasMany(Order::class, 'client_id');
    }

    public function cart(): HasMany
    {
        return $this->hasMany(Cart::class);
    }

    public function favorites(): HasMany
    {
        return $this->hasMany(Favorite::class);
    }

    public function subscriptions(): HasMany
    {
        return $this->hasMany(Subscription::class);
    }

    public function subscriptionRequests(): HasMany
    {
        return $this->hasMany(SubscriptionRequest::class);
    }

    public function aiUsages(): HasMany
    {
        return $this->hasMany(AiUsage::class);
    }

    public function aiRequests(): HasMany
    {
        return $this->hasMany(AiRequest::class);
    }

    public function aiSettings(): HasOne
    {
        return $this->hasOne(AiSetting::class);
    }

    public function favoriteProducts(): BelongsToMany
    {
        return $this->belongsToMany(Product::class, 'favorites')
            ->withTimestamps();
    }

    public function followedStores(): BelongsToMany
    {
        return $this->belongsToMany(Store::class, 'store_follows')
            ->withTimestamps();
    }

    public function deviceTokens(): HasMany
    {
        return $this->hasMany(UserDeviceToken::class);
    }

    // -------------------------------------------------------------------------
    // Scopes
    // -------------------------------------------------------------------------

    public function scopeMerchants($query)
    {
        return $query->where('role', 'merchant');
    }

    public function scopeClients($query)
    {
        return $query->where('role', 'client');
    }

    public function scopeActive($query)
    {
        return $query->where('status', 'active');
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    public function sendEmailVerificationNotification(): void
    {
        $this->notify(new QueuedVerifyEmail());
    }

    public function isMerchant(): bool
    {
        return $this->role === 'merchant';
    }

    public function isClient(): bool
    {
        return $this->role === 'client';
    }

    public function isAdmin(): bool
    {
        return $this->role === 'admin';
    }

    public function isActive(): bool
    {
        return $this->status === 'active';
    }

    public function isBanned(): bool
    {
        return $this->status === 'banned';
    }
}
