<?php

namespace App\Http\Requests\Subscription;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Validates the payload for a merchant submitting a new subscription
 * request (manual payment — no gateway involved).
 */
class StoreSubscriptionRequestRequest extends FormRequest
{
    public function authorize(): bool
    {
        // SubscriptionRequestPolicy::create() is enforced inside the controller.
        return true;
    }

    public function rules(): array
    {
        return [
            'plan_id'              => ['required', 'integer', 'exists:plans,id'],
            'billing_cycle'        => ['required', 'in:monthly,yearly'],
            'full_name'            => ['required', 'string', 'max:150'],
            'phone'                => ['required', 'string', 'max:20'],
            'payment_method'       => ['required', 'string', 'max:50'],
            'payment_proof_image'  => ['required', 'image', 'mimes:jpeg,jpg,png,webp', 'max:4096'],
            'notes'                => ['sometimes', 'nullable', 'string', 'max:1000'],
        ];
    }

    public function messages(): array
    {
        return [
            'plan_id.required'             => 'Please select a plan.',
            'plan_id.exists'               => 'The selected plan does not exist.',
            'billing_cycle.required'       => 'Please select a billing cycle.',
            'billing_cycle.in'             => 'Billing cycle must be either monthly or yearly.',
            'full_name.required'           => 'Full name is required.',
            'phone.required'               => 'Phone number is required.',
            'payment_method.required'      => 'Payment method is required.',
            'payment_proof_image.required' => 'A payment proof image is required.',
            'payment_proof_image.image'    => 'The payment proof must be a valid image file.',
            'payment_proof_image.mimes'    => 'The payment proof must be a JPEG, PNG, or WebP file.',
            'payment_proof_image.max'      => 'The payment proof image may not exceed 4 MB.',
        ];
    }
}
