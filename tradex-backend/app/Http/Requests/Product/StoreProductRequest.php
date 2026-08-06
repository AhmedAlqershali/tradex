<?php

namespace App\Http\Requests\Product;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreProductRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // ownership enforced in ProductPolicy
    }

    public function rules(): array
    {
        return [
            'store_id'    => [
                'required',
                'integer',
                // Ensures the store_id exists AND belongs to the authenticated merchant
                Rule::exists('stores', 'id')->where('user_id', $this->user()->id),
            ],
            'category_id' => ['nullable', 'integer', 'exists:categories,id'],
            'name'        => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string', 'max:5000'],
            'price'       => ['required', 'numeric', 'min:0', 'max:9999999.99'],
            'quantity'    => ['required', 'integer', 'min:0'],
            'status'      => ['nullable', 'string', Rule::in(['active', 'inactive', 'out_of_stock'])],
            'images'      => ['nullable', 'array', 'max:10'],
            'images.*'    => [
                'file',
                'image',
                'max:2048', // 2 MB each
                'mimes:jpeg,jpg,png,webp',
            ],
        ];
    }

    public function messages(): array
    {
        return [
            'store_id.exists'    => 'The selected store does not exist or does not belong to you.',
            'price.min'          => 'Price must be a positive number.',
            'images.max'         => 'You may upload a maximum of 10 images.',
            'images.*.image'     => 'Each file must be a valid image.',
            'images.*.max'       => 'Each image must not exceed 2 MB.',
            'images.*.mimes'     => 'Accepted image formats: jpeg, jpg, png, webp.',
        ];
    }
}
