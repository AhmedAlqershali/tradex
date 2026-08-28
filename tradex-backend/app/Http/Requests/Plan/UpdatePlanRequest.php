<?php

namespace App\Http\Requests\Plan;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use App\Models\Plan;

/**
 * Validates the payload for updating an existing plan.
 * All fields are optional — only provided fields are changed.
 */
class UpdatePlanRequest extends FormRequest
{
    public function authorize(): bool
    {
        // PlanPolicy::update() is enforced inside the controller.
        return true;
    }

    public function rules(): array
    {
        $planId = $this->route('id');

        return [
            'name'            => ['sometimes', 'string', 'max:50', 'alpha_dash', Rule::unique('plans', 'name')->ignore($planId), Rule::notIn(['free', 'free_trial'])],
            'display_name'    => ['sometimes', 'string', 'max:100'],
            'monthly_price'   => ['sometimes', 'numeric', 'in:' . Plan::MONTHLY_PRICE],
            'yearly_price'    => ['sometimes', 'numeric', 'in:' . Plan::YEARLY_PRICE],
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
            'name.alpha_dash' => 'Plan name may only contain letters, numbers, dashes and underscores.',
            'name.unique'     => 'A plan with this name already exists.',
            'store_limit.min' => 'Store limit must be at least 1.',
            'status.in'        => 'Status must be either active or inactive.',
        ];
    }
}
