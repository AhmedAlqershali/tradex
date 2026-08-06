<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateUserStatusRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // Gate check is handled in the controller via Policy
    }

    public function rules(): array
    {
        return [
            'status' => ['required', 'string', Rule::in(['active', 'inactive', 'banned'])],
        ];
    }

    public function messages(): array
    {
        return [
            'status.in' => 'Status must be one of: active, inactive, banned.',
        ];
    }
}
