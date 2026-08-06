<?php

namespace App\Http\Requests\Category;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Validates the payload for creating a new category.
 */
class StoreCategoryRequest extends FormRequest
{
    public function authorize(): bool
    {
        // CategoryPolicy::create() is enforced inside the controller.
        return true;
    }

    public function rules(): array
    {
        return [
            'name'   => ['required', 'string', 'max:100', 'unique:categories,name'],
            'image'  => ['sometimes', 'nullable', 'image', 'mimes:jpeg,jpg,png,webp', 'max:2048'],
            'status' => ['sometimes', 'in:active,inactive'],
        ];
    }

    public function messages(): array
    {
        return [
            'name.required' => 'Category name is required.',
            'name.unique'   => 'A category with this name already exists.',
            'name.max'      => 'Category name may not exceed 100 characters.',
            'image.image'   => 'The image must be a valid image file.',
            'image.mimes'   => 'The image must be a JPEG, PNG, or WebP file.',
            'image.max'     => 'The image may not exceed 2 MB.',
            'status.in'     => 'Status must be either active or inactive.',
        ];
    }
}
