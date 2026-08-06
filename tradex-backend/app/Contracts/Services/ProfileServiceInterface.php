<?php

namespace App\Contracts\Services;

use App\Models\User;
use Illuminate\Http\UploadedFile;

interface ProfileServiceInterface
{
    /** Return the authenticated user's profile data. */
    public function getProfile(User $user): array;

    /**
     * Update profile information (name, email, phone).
     *
     * @throws \Illuminate\Validation\ValidationException  if email already taken by another user
     */
    public function updateProfile(User $user, array $data): array;

    /**
     * Change the user's password.
     *
     * @throws \Illuminate\Validation\ValidationException  if current password is wrong
     */
    public function changePassword(User $user, string $currentPassword, string $newPassword): void;

    /**
     * Upload a new avatar image and update the user record.
     * Deletes the previous avatar from storage.
     */
    public function updateAvatar(User $user, UploadedFile $file): array;
}
