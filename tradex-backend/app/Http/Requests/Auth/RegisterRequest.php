<?php

namespace App\Http\Requests\Auth;

use Illuminate\Foundation\Http\FormRequest;

class RegisterRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name'     => ['required', 'string', 'max:100'],
            'email'    => ['required', 'email', 'max:255', 'unique:users,email'],
            'phone'    => ['nullable', 'string', 'max:20'],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
            'role'     => ['nullable', 'string', 'in:client,merchant'],
        ];
    }

    public function messages(): array
    {
        return [
            'email.unique'          => 'This email address is already registered.',
            'password.confirmed'    => 'Password confirmation does not match.',
            'password.min'          => 'Password must be at least 8 characters.',
            'role.in'               => 'Role must be either client or merchant.',
        ];
    }
}
