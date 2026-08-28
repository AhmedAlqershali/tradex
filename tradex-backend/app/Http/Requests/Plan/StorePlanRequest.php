<?php

namespace App\Http\Requests\Plan;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use App\Models\Plan;

/**
 * Validates the payload for creating a new plan.
 */
class StorePlanRequest extends FormRequest
{
    public function authorize(): bool
    {
        // PlanPolicy::create() is enforced inside the controller.
        return true;
    }

    public function rules(): array
    {
        return [
            'name'            => ['required', 'string', 'max:50', 'alpha_dash', 'unique:plans,name', Rule::notIn(['free', 'free_trial'])],
            'display_name'    => ['required', 'string', 'max:100'],
            'monthly_price'   => ['required', 'numeric', 'in:' . Plan::MONTHLY_PRICE],
            'yearly_price'    => ['required', 'numeric', 'in:' . Plan::YEARLY_PRICE],
            'ai_usage_limit'  => ['sometimes', 'nullable', 'integer', 'min:0'],
            'product_limit'   => ['sometimes', 'nullable', 'integer', 'min:0'],
            'store_limit'     => ['sometimes', 'integer', 'min:1'],
            'features'        => ['sometimes', 'nullable', 'array'],
            'status'          => ['sometimes', 'in:active,inactive'],
        ];
    }

    public function messages(): array
    {
        return [
            'name.required'         => 'Plan name is required.',
            'name.alpha_dash'       => 'Plan name may only contain letters, numbers, dashes and underscores.',
            'name.unique'           => 'A plan with this name already exists.',
            'display_name.required' => 'Display name is required.',
            'monthly_price.required' => 'Monthly price is required.',
            'yearly_price.required'  => 'Yearly price is required.',
            'store_limit.min'        => 'Store limit must be at least 1.',
            'status.in'               => 'Status must be either active or inactive.',
        ];
    }
}
