<?php

namespace App\Http\Requests\Auth;

use Illuminate\Foundation\Http\FormRequest;
class ResetPasswordRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'token'    => ['required', 'string'],
            'email'    => ['required', 'email', 'max:255'],
            'password' => ['required', 'string', 'min:6', 'confirmed'],
        ];
    }

    public function messages(): array
    {
        return [
            'token.required'    => 'A valid reset token is required.',
            'email.required'    => 'Email address is required.',
            'password.required' => 'A new password is required.',
            'password.confirmed'=> 'Password confirmation does not match.',
        ];
    }
}
