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
            'context'  => ['required', 'string', 'min:5', 'max:500'],
            'language' => ['nullable', 'string', 'max:50'],
        ];
    }

    public function messages(): array
    {
        return [
            'context.required' => 'Product context is required (e.g. product name, category, key features).',
            'context.min'      => 'Please provide at least 5 characters of product context.',
            'context.max'      => 'Product context must not exceed 500 characters.',
        ];
    }
}
