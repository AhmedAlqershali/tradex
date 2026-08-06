<?php

namespace App\Http\Requests\AI;

use Illuminate\Foundation\Http\FormRequest;

class CustomerReplyRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // role:merchant enforced at route level
    }

    public function rules(): array
    {
        return [
            'context'    => ['required', 'string', 'min:5', 'max:1000'],
            'language'   => ['nullable', 'string', 'max:50'],
            'store_name' => ['nullable', 'string', 'max:255'],
        ];
    }

    public function messages(): array
    {
        return [
            'context.required' => 'Customer message context is required.',
            'context.min'      => 'Please provide at least 5 characters of customer message context.',
            'context.max'      => 'Customer message must not exceed 1000 characters.',
        ];
    }
}
