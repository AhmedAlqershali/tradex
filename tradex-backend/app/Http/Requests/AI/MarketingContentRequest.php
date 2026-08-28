<?php

namespace App\Http\Requests\AI;

use Illuminate\Foundation\Http\FormRequest;

class MarketingContentRequest extends FormRequest
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
            'purpose'  => ['nullable', 'string', 'in:instagram,hashtags'],
        ];
    }

    public function messages(): array
    {
        return [
            'context.required' => 'Campaign context is required (e.g. product name, promotion details).',
            'context.min'      => 'Please provide at least 5 characters of campaign context.',
            'context.max'      => 'Campaign context must not exceed 500 characters.',
        ];
    }
}
