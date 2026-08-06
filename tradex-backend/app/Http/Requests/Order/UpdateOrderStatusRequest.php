<?php

namespace App\Http\Requests\Order;

use App\Models\Order;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateOrderStatusRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'status' => [
                'required',
                'string',
                Rule::in(Order::MERCHANT_ALLOWED_STATUSES),
            ],
        ];
    }

    public function messages(): array
    {
        $allowed = implode(', ', Order::MERCHANT_ALLOWED_STATUSES);

        return [
            'status.in' => "Status must be one of: {$allowed}.",
        ];
    }
}
