<?php

namespace App\Http\Requests\Product;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateProductRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // ownership enforced in ProductPolicy
    }

    public function rules(): array
    {
        return [
            // store_id is not updatable — a product cannot be moved between stores
            'category_id'    => ['nullable', 'integer', 'exists:categories,id'],
            'name'           => ['sometimes', 'required', 'string', 'max:255'],
            'description'    => ['nullable', 'string', 'max:5000'],
            'price'          => ['sometimes', 'required', 'numeric', 'min:0', 'max:9999999.99'],
            'quantity'       => ['sometimes', 'required', 'integer', 'min:0'],
            'status'         => ['nullable', 'string', Rule::in(['active', 'inactive', 'out_of_stock'])],
            'images'         => ['nullable', 'array', 'max:10'],
            'images.*'       => [
                'file',
                'image',
                'max:2048',
                'mimes:jpeg,jpg,png,webp',
            ],
            // When true, all existing images are removed (before adding new ones)
            'clear_images'   => ['nullable', 'boolean'],
        ];
    }

    public function messages(): array
    {
        return [
            'price.min'      => 'Price must be a positive number.',
            'images.max'     => 'You may upload a maximum of 10 images.',
            'images.*.image' => 'Each file must be a valid image.',
            'images.*.max'   => 'Each image must not exceed 2 MB.',
            'images.*.mimes' => 'Accepted image formats: jpeg, jpg, png, webp.',
        ];
    }
}
