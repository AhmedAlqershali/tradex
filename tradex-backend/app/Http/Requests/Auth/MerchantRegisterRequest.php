<?php

namespace App\Http\Requests\Auth;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rules\Password;

class MerchantRegisterRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name'               => ['required', 'string', 'max:100'],
            'email'              => ['required', 'email', 'max:255', 'unique:users,email'],
            'phone'              => ['required', 'string', 'max:20'],
            'password'           => [
                'required',
                'confirmed',
                Password::min(8)
                    ->letters()
                    ->mixedCase()
                    ->numbers()
                    ->uncompromised(),
            ],
            'store_name'         => ['required', 'string', 'max:100'],
            'store_description'  => ['nullable', 'string', 'max:1000'],
        ];
    }

    public function messages(): array
    {
        return [
            'email.unique'          => 'This email address is already registered.',
            'password.confirmed'    => 'Password confirmation does not match.',
            'store_name.required'   => 'A store name is required for merchant registration.',
        ];
    }
}
