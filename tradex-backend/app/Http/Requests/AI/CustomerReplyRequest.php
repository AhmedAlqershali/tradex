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
            'context'    => ['required', 'string', 'not_regex:/^\s*$/', 'max:1000'],
            'language'   => ['nullable', 'string', 'max:50'],
            'store_name' => ['nullable', 'string', 'max:255'],
        ];
    }

    public function messages(): array
    {
        return [
            'context.required' => 'Customer message context is required.',
            'context.not_regex' => 'Customer message cannot be empty.',
            'context.max'      => 'Customer message must not exceed 1000 characters.',
        ];
    }
}
