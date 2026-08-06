<?php

namespace App\Http\Requests\Auth;

use Illuminate\Foundation\Http\FormRequest;

/**
 * POST /api/v1/auth/password/forgot
 *
 * Intentionally accepts any email — valid or not — and returns a generic
 * success response regardless, to avoid leaking user existence information.
 * The email-exists check is handled by the Password broker internally.
 */
class ForgotPasswordRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'email' => ['required', 'email', 'max:255'],
        ];
    }

    public function messages(): array
    {
        return [
            'email.required' => 'Email address is required.',
            'email.email'    => 'Please provide a valid email address.',
        ];
    }
}
