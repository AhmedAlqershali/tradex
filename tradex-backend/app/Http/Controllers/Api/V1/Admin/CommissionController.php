<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Api\V1\BaseApiController;
use App\Models\Commission;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CommissionController extends BaseApiController
{
    public function index(Request $request): JsonResponse
    {
        $this->authorize('viewAny', Commission::class);

        $perPage = min((int) ($request->query('per_page', 15)), 100);
        $search = trim((string) $request->query('search', ''));
        $paymentStatus = trim((string) $request->query('payment_status', ''));

        $commissions = Commission::query()
            ->with(['order', 'merchant', 'store'])
            ->when($paymentStatus !== '', fn ($query) => $query->where('payment_status', $paymentStatus))
            ->when($search !== '', function ($query) use ($search) {
                $query->where(function ($innerQuery) use ($search) {
                    $innerQuery->where('order_id', 'like', "%{$search}%")
                        ->orWhereHas('merchant', function ($merchantQuery) use ($search) {
                            $merchantQuery->where('name', 'like', "%{$search}%")
                                ->orWhere('email', 'like', "%{$search}%");
                        })
                        ->orWhereHas('order', function ($orderQuery) use ($search) {
                            $orderQuery->where('customer_phone', 'like', "%{$search}%")
                                ->orWhere('id', 'like', "%{$search}%");
                        });
                });
            })
            ->orderByDesc('created_at')
            ->paginate($perPage)
            ->withQueryString();

        return $this->success($commissions, 'Commissions retrieved successfully.');
    }

    public function show(int $id): JsonResponse
    {
        $commission = Commission::query()->with(['order', 'merchant', 'store'])->find($id);

        if (! $commission) {
            return $this->notFound('Commission not found.');
        }

        $this->authorize('view', $commission);

        return $this->success($commission, 'Commission retrieved successfully.');
    }

    public function markPaid(Request $request, int $id): JsonResponse
    {
        $commission = Commission::query()->find($id);

        if (! $commission) {
            return $this->notFound('Commission not found.');
        }

        $this->authorize('update', $commission);

        if ($commission->payment_status === 'paid') {
            return $this->error('Commission payment has already been recorded.', 409);
        }

        $admin = $request->user();
        $commission->update([
            'payment_status' => 'paid',
            'paid_at' => now(),
            'paid_by' => $admin->id,
            'recorded_by' => $admin->id,
        ]);

        return $this->success($commission->fresh(['order', 'merchant', 'store']), 'Commission payment recorded successfully.');
    }
}
