<?php

namespace App\Http\Requests\Subscription;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Validates the payload for an admin rejecting a subscription request.
 */
class RejectSubscriptionRequestRequest extends FormRequest
{
    public function authorize(): bool
    {
        // SubscriptionRequestPolicy::reject() is enforced inside the controller.
        return true;
    }

    public function rules(): array
    {
        return [
            'rejection_reason' => ['required', 'string', 'max:500'],
        ];
    }

    public function messages(): array
    {
        return [
            'rejection_reason.required' => 'A rejection reason is required.',
            'rejection_reason.max'      => 'The rejection reason may not exceed 500 characters.',
        ];
    }
}
