<?php

namespace App\Http\Requests\Review;

use Illuminate\Foundation\Http\FormRequest;

class StoreReviewRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'rating'  => ['required', 'integer', 'min:1', 'max:5'],
            'comment' => ['nullable', 'string', 'max:2000'],
        ];
    }

    public function messages(): array
    {
        return [
            'rating.required' => 'A rating between 1 and 5 is required.',
            'rating.min'      => 'Rating must be at least 1.',
            'rating.max'      => 'Rating must not exceed 5.',
            'comment.max'     => 'Comment may not exceed 2000 characters.',
        ];
    }
}
