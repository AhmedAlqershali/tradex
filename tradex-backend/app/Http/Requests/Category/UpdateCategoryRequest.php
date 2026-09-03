<?php

namespace App\Http\Requests\Category;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Validates the payload for updating an existing category.
 *
 * All fields are optional (PATCH-style). The name uniqueness rule
 * ignores the current category so a no-op rename does not fail.
 */
class UpdateCategoryRequest extends FormRequest
{
    public function authorize(): bool
    {
        // CategoryPolicy::update() is enforced inside the controller.
        return true;
    }

    public function rules(): array
    {
        // The route parameter is `{id}` — used to exclude this record
        // from the unique constraint check so unchanged names pass validation.
        $categoryId = $this->route('id');

        return [
            'name'    => [
                'sometimes',
                'string',
                'max:100',
                Rule::unique('categories', 'name')->ignore($categoryId),
            ],
            'name_ar' => ['sometimes', 'nullable', 'string', 'max:100'],
            'name_en' => ['sometimes', 'nullable', 'string', 'max:100'],
            'image'   => ['sometimes', 'nullable', 'image', 'mimes:jpeg,jpg,png,webp', 'max:2048'],
            'status'  => ['sometimes', 'in:active,inactive'],
        ];
    }

    public function messages(): array
    {
        return [
            'name.unique'   => 'A category with this name already exists.',
            'name.max'      => 'Category name may not exceed 100 characters.',
            'image.image'   => 'The image must be a valid image file.',
            'image.mimes'   => 'The image must be a JPEG, PNG, or WebP file.',
            'image.max'     => 'The image may not exceed 2 MB.',
            'status.in'     => 'Status must be either active or inactive.',
        ];
    }
}
