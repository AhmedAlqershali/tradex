<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateStoreStatusRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // Gate check is handled in the controller via Policy
    }

    public function rules(): array
    {
        return [
            'status' => ['required', 'string', Rule::in(['active', 'inactive', 'suspended'])],
        ];
    }

    public function messages(): array
    {
        return [
            'status.in' => 'Status must be one of: active, inactive, suspended.',
        ];
    }
}
