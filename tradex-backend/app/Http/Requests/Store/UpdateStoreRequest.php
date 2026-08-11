<?php

namespace App\Http\Requests\Store;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Validates the payload for updating a merchant's store profile, including
 * the region used by client-side store discovery.
 *
 * All fields are optional (PATCH-style update) — at least one must be
 * provided; the controller returns the unchanged record if the payload
 * is empty, so no minimum-one-field rule is enforced here.
 */
class UpdateStoreRequest extends FormRequest
{
    public function authorize(): bool
    {
        // Ownership is enforced by StorePolicy::update() inside the controller.
        return true;
    }

    public function rules(): array
    {
        return [
            'store_name'  => ['sometimes', 'string', 'min:2', 'max:100'],
            'description' => ['sometimes', 'nullable', 'string', 'max:1000'],
            'region'     => ['sometimes', 'nullable', 'string', 'max:100'],
            'phone'       => ['sometimes', 'nullable', 'string', 'max:20'],
        ];
    }

    public function messages(): array
    {
        return [
            'store_name.min'  => 'Store name must be at least 2 characters.',
            'store_name.max'  => 'Store name may not exceed 100 characters.',
            'description.max' => 'Description may not exceed 1000 characters.',
        ];
    }
}
