<?php

namespace App\Http\Requests\Store;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Validates the logo image upload for a merchant store.
 */
class UpdateStoreLogoRequest extends FormRequest
{
    public function authorize(): bool
    {
        // Ownership is enforced by StorePolicy::update() inside the controller.
        return true;
    }

    public function rules(): array
    {
        return [
            'logo' => ['required', 'image', 'mimes:jpeg,jpg,png,webp', 'max:2048'],
        ];
    }

    public function messages(): array
    {
        return [
            'logo.required' => 'A logo image file is required.',
            'logo.image'    => 'The uploaded file must be an image.',
            'logo.mimes'    => 'The logo must be a JPEG, PNG, or WebP image.',
            'logo.max'      => 'The logo may not exceed 2 MB.',
        ];
    }
}
