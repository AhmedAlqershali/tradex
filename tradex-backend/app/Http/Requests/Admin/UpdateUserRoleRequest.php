<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateUserRoleRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // Gate check is handled in the controller via Policy
    }

    public function rules(): array
    {
        return [
            'role' => ['required', 'string', Rule::in(['client', 'merchant', 'admin'])],
        ];
    }

    public function messages(): array
    {
        return [
            'role.in' => 'Role must be one of: client, merchant, admin.',
        ];
    }
}
