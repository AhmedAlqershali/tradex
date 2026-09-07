<?php

namespace App\Http\Requests\AI;

use Illuminate\Foundation\Http\FormRequest;

class ProductDescriptionRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // role:merchant enforced at route level
    }

    public function rules(): array
    {
        return [
            'context'  => ['required', 'string', 'not_regex:/^\s*$/', 'max:500'],
            'language' => ['nullable', 'string', 'max:50'],
        ];
    }

    public function messages(): array
    {
        return [
            'context.required' => 'Product context is required (e.g. product name, category, key features).',
            'context.not_regex' => 'Product context cannot be empty.',
            'context.max'      => 'Product context must not exceed 500 characters.',
        ];
    }
}
